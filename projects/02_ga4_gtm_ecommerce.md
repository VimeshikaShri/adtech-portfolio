# GA4 + GTM Ecommerce Implementation

## Objective

Create a durable ecommerce event taxonomy that supports product-funnel analysis, audience activation, and merchandising decisions without relying on fragile page-scraping rules.

## Event map

| Funnel stage | GA4 event | Important parameters | Why it matters |
| --- | --- | --- | --- |
| Discovery | `view_item_list` | `item_list_id`, `items` | List and category performance |
| Product intent | `view_item` | `items`, `value`, `currency` | Product detail engagement |
| Cart intent | `add_to_cart` | `items`, `value`, `currency` | Add-to-cart rate |
| Checkout | `begin_checkout` | `coupon`, `items`, `value` | Checkout abandonment |
| Revenue | `purchase` | `transaction_id`, `tax`, `shipping`, `items` | Revenue and ROAS |
| Reversal | `refund` | `transaction_id`, `value`, `items` | Net-revenue reporting |

## Implementation principles

- Push a clean `dataLayer` object from the application—do not parse the DOM for price, SKU, or order value.
- Use GA4 recommended ecommerce event names and the prescribed `items` array schema.
- Set user properties sparingly, never place PII in GA4, and register only parameters that will be reported as custom dimensions.
- Persist campaign identifiers only where consent and retention policy allow it.

## GTM trigger pattern

Use Custom Event triggers for `view_item`, `add_to_cart`, `begin_checkout`, and `purchase`. Every GA4 Event tag references the same reusable Data Layer Variables, which reduces drift between tags. Build a single event QA sheet containing event, trigger, parameter, expected value, and test URL/order.

## Example validation query

```sql
-- GA4 BigQuery export: check whether purchase events have usable identifiers
SELECT
  event_date,
  COUNT(*) AS purchases,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params)
           WHERE key = 'transaction_id') IS NOT NULL) AS with_transaction_id
FROM `project.analytics_123456789.events_*`
WHERE event_name = 'purchase'
GROUP BY 1
ORDER BY 1 DESC;
```

## Outcome to demonstrate

With a consistent item schema, the team can answer “Which product collections create first-time buyers?” and “Where does checkout intent break?” without requesting an analyst to rebuild the logic every week.
