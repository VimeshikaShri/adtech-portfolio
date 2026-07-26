# Looker Studio Marketing Dashboard

## Decision the dashboard supports

The weekly media review: where should the team protect budget, investigate performance, or change creative/targeting next?

## Data sources

| Source | Fields used | Refresh |
| --- | --- | --- |
| Google Ads connector | Spend, impressions, clicks, conversions | Daily |
| GA4 | Sessions, purchases, revenue, source/medium | Daily |
| BigQuery blend | Normalized channel names, attributed revenue, new customers | Daily |
| Budget sheet | Monthly channel plan and owner | Manual / weekly |

## Page structure

### 1. Executive overview

Scorecards: spend, revenue, blended ROAS, CPA, new-customer revenue. Include period-over-period comparison and a clear data freshness timestamp.

### 2. Channel decision board

One row per normalized channel. Show spend, revenue, ROAS, CPA, budget pace, and week-over-week change. Use conditional formatting only for defined action thresholds—avoid decorative red/green signals.

### 3. Campaign diagnostics

Controls for channel, campaign, device, and landing page. A time series pairs spend with revenue or conversions; a detail table exposes the campaign-level drivers.

### 4. Acquisition quality

Compare first purchase revenue, 30-day repeat rate, and new-customer CPA by channel. This stops last-click ROAS from being the only growth signal.

## Calculated fields

```text
Blended ROAS = SUM(Revenue) / SUM(Spend)
CPA = SUM(Spend) / SUM(Conversions)
Budget pace = SUM(Spend) / SUM(Planned spend to date)
New-customer rate = SUM(New customers) / SUM(Customers)
```

## Design notes

Use one reporting currency, a visible date control, and a documented channel mapping. Label platform conversions separately from GA4/warehouse conversions so the dashboard does not imply that they are interchangeable.
