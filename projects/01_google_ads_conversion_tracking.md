# Google Ads Conversion Tracking

## Objective

Measure qualified ecommerce purchases in Google Ads with a stable transaction identifier, value/currency accuracy, consent-aware behavior, and no duplicate conversion inflation.

## Measurement design

| Event | Trigger | Required parameters | Destination |
| --- | --- | --- | --- |
| `purchase` | Order-confirmation page or backend webhook | `transaction_id`, `value`, `currency`, `items` | GA4 + Google Ads |
| `generate_lead` | Qualified lead form success | `lead_id`, `value`, `currency` | GA4 + Google Ads |
| Enhanced conversion | First-party customer data available at conversion | hashed email/phone/address | Google Ads only |

The `transaction_id` is used as the deduplication key. Browser and server events may both send a purchase, but only one should be counted by the destination.

## Data layer contract

```javascript
window.dataLayer = window.dataLayer || [];
window.dataLayer.push({
  event: 'purchase',
  ecommerce: {
    transaction_id: 'ORDER-10482',
    value: 129.00,
    tax: 12.90,
    shipping: 0,
    currency: 'USD',
    coupon: 'WELCOME10',
    items: [{
      item_id: 'SKU-LEMON-01',
      item_name: 'Daily SPF 50',
      price: 43.00,
      quantity: 3,
      item_category: 'Skincare'
    }]
  }
});
```

## GTM configuration

1. Create Data Layer Variables for `ecommerce.transaction_id`, `ecommerce.value`, `ecommerce.currency`, and `ecommerce.items`.
2. Fire a GA4 Event tag on the custom event `purchase`; map the ecommerce object.
3. Fire the Google Ads Conversion Tracking tag on the same event; map Conversion Value, Currency Code, and Transaction ID.
4. Configure Consent Mode v2 defaults before any Google tags fire; update on CMP choice.
5. Enable enhanced conversions only with an approved first-party-data collection and hashing flow.

## QA checklist

- Use GTM Preview to confirm one `purchase` event and one tag firing per order.
- Compare the order ID and total against the order-management system for a test order.
- Confirm GA4 DebugView parameters, then validate Google Ads diagnostics after processing.
- Test accepted, rejected, and unchanged consent states in a clean browser profile.
- Document attribution differences: GA4 and Google Ads will not reconcile exactly because of their different models and lookback windows.

## Portfolio talking point

“I started with the business definition of a conversion, made the event idempotent with a transaction key, then tested the whole path—data layer, GTM, GA4, and Ads—rather than treating a green tag status as proof of measurement quality.”
