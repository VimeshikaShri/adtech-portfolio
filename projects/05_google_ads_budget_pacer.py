"""Daily Google Ads budget pacing monitor.

Use a Google Ads developer token and OAuth credentials configured in google-ads.yaml.
The script compares month-to-date cost to the expected spend for the current day,
then prints exceptions suitable for Slack, email, or a workflow scheduler.
"""

from __future__ import annotations

import calendar
import datetime as dt
from dataclasses import dataclass

from google.ads.googleads.client import GoogleAdsClient


@dataclass
class CampaignPace:
    campaign: str
    cost_to_date: float
    monthly_budget: float
    expected_to_date: float

    @property
    def variance_pct(self) -> float:
        return (self.cost_to_date / self.expected_to_date) - 1 if self.expected_to_date else 0


def fetch_costs(client: GoogleAdsClient, customer_id: str) -> list[tuple[str, float]]:
    """Return current-month campaign spend in account currency units."""
    query = """
      SELECT campaign.name, metrics.cost_micros
      FROM campaign
      WHERE segments.date DURING THIS_MONTH
        AND campaign.status = ENABLED
    """
    service = client.get_service("GoogleAdsService")
    rows = service.search(customer_id=customer_id, query=query)
    return [(row.campaign.name, row.metrics.cost_micros / 1_000_000) for row in rows]


def expected_spend(monthly_budget: float, today: dt.date) -> float:
    """Simple calendar-day pacing. Substitute weighted pacing for seasonal businesses."""
    days_in_month = calendar.monthrange(today.year, today.month)[1]
    return monthly_budget * (today.day / days_in_month)


def build_exceptions(
    actuals: list[tuple[str, float]], budgets: dict[str, float], today: dt.date, threshold: float = 0.08
) -> list[CampaignPace]:
    exceptions = []
    for campaign, cost in actuals:
        budget = budgets.get(campaign)
        if budget is None:
            continue  # Include an unmapped-campaign alert in production.
        pace = CampaignPace(campaign, cost, budget, expected_spend(budget, today))
        if abs(pace.variance_pct) >= threshold:
            exceptions.append(pace)
    return sorted(exceptions, key=lambda x: abs(x.variance_pct), reverse=True)


if __name__ == "__main__":
    # In production, load this from a governed Sheet or database, not source code.
    campaign_budgets = {"Brand Search": 18000, "Non-brand Search": 30000, "Prospecting PMax": 44000}
    client = GoogleAdsClient.load_from_storage("google-ads.yaml")
    customer_id = "INSERT_CUSTOMER_ID_WITHOUT_HYPHENS"
    alerts = build_exceptions(fetch_costs(client, customer_id), campaign_budgets, dt.date.today())

    for alert in alerts:
        direction = "over" if alert.variance_pct > 0 else "under"
        print(f"{alert.campaign}: {abs(alert.variance_pct):.1%} {direction} pace | "
              f"${alert.cost_to_date:,.0f} actual vs ${alert.expected_to_date:,.0f} expected")
