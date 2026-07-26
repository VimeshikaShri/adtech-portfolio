-- BigQuery Marketing Analytics
-- Purpose: channel-level daily sessions, purchases, and revenue from GA4 export.
-- Replace the project/dataset and adjust the attribution rule for production use.

WITH session_starts AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS date,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params)
      WHERE key = 'ga_session_id') AS session_id,
    COALESCE(NULLIF(collected_traffic_source.manual_source, ''), '(direct)') AS source,
    COALESCE(NULLIF(collected_traffic_source.manual_medium, ''), '(none)') AS medium
  FROM `project.analytics_123456789.events_*`
  WHERE event_name = 'session_start'
),

purchases AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS date,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params)
      WHERE key = 'ga_session_id') AS session_id,
    (SELECT value.string_value FROM UNNEST(event_params)
      WHERE key = 'transaction_id') AS transaction_id,
    (SELECT value.double_value FROM UNNEST(event_params)
      WHERE key = 'value') AS revenue
  FROM `project.analytics_123456789.events_*`
  WHERE event_name = 'purchase'
),

channel_performance AS (
  SELECT
    s.date,
    CASE
      WHEN LOWER(s.medium) IN ('cpc', 'ppc', 'paidsearch') THEN 'Paid Search'
      WHEN LOWER(s.medium) IN ('paid_social', 'paidsocial') THEN 'Paid Social'
      WHEN LOWER(s.medium) IN ('display', 'cpm') THEN 'Display'
      WHEN s.source = '(direct)' THEN 'Direct'
      ELSE 'Organic / Referral'
    END AS channel,
    COUNT(DISTINCT CONCAT(s.user_pseudo_id, '-', CAST(s.session_id AS STRING))) AS sessions,
    COUNT(DISTINCT p.transaction_id) AS purchases,
    ROUND(SUM(COALESCE(p.revenue, 0)), 2) AS revenue
  FROM session_starts s
  LEFT JOIN purchases p
    ON s.date = p.date
    AND s.user_pseudo_id = p.user_pseudo_id
    AND s.session_id = p.session_id
  GROUP BY 1, 2
)

SELECT
  date,
  channel,
  sessions,
  purchases,
  revenue,
  SAFE_DIVIDE(purchases, sessions) AS conversion_rate,
  SAFE_DIVIDE(revenue, purchases) AS average_order_value
FROM channel_performance
ORDER BY date DESC, revenue DESC;
