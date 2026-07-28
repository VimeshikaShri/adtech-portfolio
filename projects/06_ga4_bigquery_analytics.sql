-- ============================================================================
-- GA4 BIGQUERY ANALYTICS — CORRECTED
-- Written against the actual GA4 BigQuery export schema.
-- ============================================================================
--
-- HOW TO USE
-- ----------
-- Every query below uses this table reference:
--
--     `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
--
-- That is Google's public GA4 sample (Nov 2020 - Jan 2021). It has the same
-- schema as your own export, so you can develop against it today.
--
-- When your own export lands, swap that reference for:
--
--     `project-f3310b3f-c096-49d1-a35.analytics_547243036.events_*`
--
-- and change the _TABLE_SUFFIX range to recent dates. Nothing else changes.
--
--
-- SCHEMA NOTES (these are what the earlier version got wrong)
-- ----------------------------------------------------------
--   traffic_source.name          campaign name. There is NO .campaign field.
--   event_timestamp              MICROseconds -> use TIMESTAMP_MICROS, not MILLIS
--   ecommerce.purchase_revenue   revenue. There is NO top-level event_value.
--   page_location                lives inside event_params, needs UNNEST
--   event_params                 unordered repeated field. Never use
--                                event_params[OFFSET(0)] — filter by key.
--
--
-- COST
-- ----
-- The events_* wildcard scans every daily table unless _TABLE_SUFFIX is
-- filtered. Every query below keeps that filter. Check the byte estimate under
-- the editor before running. On-demand free tier is 1 TB/month.
-- ============================================================================


-- ============================================================================
-- 0. SANITY CHECK — what events exist and in what volume?
-- Run this first against any new dataset. It tells you which of the queries
-- below will actually return data.
-- ============================================================================

SELECT
  event_name,
  COUNT(*)                       AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
GROUP BY event_name
ORDER BY events DESC;


-- ============================================================================
-- 1. ACQUISITION FUNNEL BY SOURCE / MEDIUM / CAMPAIGN
-- The core report: how many users each source brought, and how far down the
-- purchase funnel they got.
-- ============================================================================

SELECT
  traffic_source.source AS source,
  traffic_source.medium AS medium,
  traffic_source.name   AS campaign,

  COUNT(DISTINCT user_pseudo_id)                                        AS users,
  COUNT(DISTINCT IF(event_name = 'view_item',      user_pseudo_id, NULL)) AS viewed_item,
  COUNT(DISTINCT IF(event_name = 'add_to_cart',    user_pseudo_id, NULL)) AS added_to_cart,
  COUNT(DISTINCT IF(event_name = 'begin_checkout', user_pseudo_id, NULL)) AS began_checkout,
  COUNT(DISTINCT IF(event_name = 'purchase',       user_pseudo_id, NULL)) AS purchasers,

  ROUND(SAFE_DIVIDE(
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)),
    COUNT(DISTINCT user_pseudo_id)) * 100, 2)                            AS cvr_pct,

  ROUND(SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue, 0)), 2) AS revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
GROUP BY source, medium, campaign
ORDER BY users DESC
LIMIT 50;


-- ============================================================================
-- 2. STEP-TO-STEP FUNNEL DROP-OFF
-- Same funnel, but expressed as conversion rate between adjacent steps, which
-- is what actually tells you where the leak is.
-- ============================================================================

WITH user_flags AS (
  SELECT
    user_pseudo_id,
    traffic_source.medium AS medium,
    MAX(IF(event_name = 'view_item',      1, 0)) AS f_view,
    MAX(IF(event_name = 'add_to_cart',    1, 0)) AS f_cart,
    MAX(IF(event_name = 'begin_checkout', 1, 0)) AS f_checkout,
    MAX(IF(event_name = 'purchase',       1, 0)) AS f_purchase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
  GROUP BY user_pseudo_id, medium
)
SELECT
  medium,
  COUNT(*)                                   AS users,
  SUM(f_view)                                AS viewed_item,
  SUM(f_cart)                                AS added_to_cart,
  SUM(f_checkout)                            AS began_checkout,
  SUM(f_purchase)                            AS purchased,

  ROUND(SAFE_DIVIDE(SUM(f_view),     COUNT(*))      * 100, 1) AS pct_user_to_view,
  ROUND(SAFE_DIVIDE(SUM(f_cart),     SUM(f_view))   * 100, 1) AS pct_view_to_cart,
  ROUND(SAFE_DIVIDE(SUM(f_checkout), SUM(f_cart))   * 100, 1) AS pct_cart_to_checkout,
  ROUND(SAFE_DIVIDE(SUM(f_purchase), SUM(f_checkout))* 100, 1) AS pct_checkout_to_purchase
FROM user_flags
GROUP BY medium
ORDER BY users DESC;


-- ============================================================================
-- 3. REVENUE AND AOV BY SOURCE
-- transaction_id is the correct unit for counting orders — one purchase event
-- per transaction, so COUNT(DISTINCT transaction_id) beats counting users.
-- ============================================================================

SELECT
  traffic_source.source AS source,
  traffic_source.medium AS medium,
  traffic_source.name   AS campaign,
  COUNT(DISTINCT ecommerce.transaction_id)          AS transactions,
  COUNT(DISTINCT user_pseudo_id)                    AS buyers,
  ROUND(SUM(ecommerce.purchase_revenue), 2)         AS revenue,
  ROUND(SAFE_DIVIDE(SUM(ecommerce.purchase_revenue),
                    COUNT(DISTINCT ecommerce.transaction_id)), 2) AS aov,
  ROUND(SAFE_DIVIDE(SUM(ecommerce.purchase_revenue),
                    COUNT(DISTINCT user_pseudo_id)), 2)           AS revenue_per_buyer
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
  AND event_name = 'purchase'
GROUP BY source, medium, campaign
ORDER BY revenue DESC
LIMIT 50;


-- ============================================================================
-- 4. DAILY TREND
-- event_date is a STRING in YYYYMMDD form, so parse it rather than casting.
-- ============================================================================

SELECT
  PARSE_DATE('%Y%m%d', event_date) AS date,
  COUNT(DISTINCT user_pseudo_id)   AS users,

  COUNT(DISTINCT CONCAT(
    user_pseudo_id, '-',
    CAST((SELECT value.int_value FROM UNNEST(event_params)
          WHERE key = 'ga_session_id') AS STRING)
  ))                                                                      AS sessions,

  COUNT(DISTINCT IF(event_name = 'purchase', ecommerce.transaction_id, NULL)) AS transactions,
  ROUND(SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue, 0)), 2)   AS revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
GROUP BY date
ORDER BY date;


-- ============================================================================
-- 5. DEVICE PERFORMANCE
-- Useful input for Google Ads device bid adjustments.
-- ============================================================================

SELECT
  device.category                        AS device_category,
  device.operating_system                AS os,
  COUNT(DISTINCT user_pseudo_id)         AS users,
  COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL))       AS purchasers,
  ROUND(SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue, 0)), 2) AS revenue,

  ROUND(SAFE_DIVIDE(
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)),
    COUNT(DISTINCT user_pseudo_id)) * 100, 2)                            AS cvr_pct,

  ROUND(SAFE_DIVIDE(
    SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue, 0)),
    COUNT(DISTINCT user_pseudo_id)), 2)                                  AS revenue_per_user
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
GROUP BY device_category, os
HAVING users >= 100
ORDER BY users DESC;


-- ============================================================================
-- 6. GEOGRAPHIC PERFORMANCE
-- Input for location bid adjustments and market prioritisation.
-- ============================================================================

SELECT
  geo.country,
  geo.region,
  COUNT(DISTINCT user_pseudo_id)                                         AS users,
  COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL))       AS purchasers,
  ROUND(SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue, 0)), 2) AS revenue,
  ROUND(SAFE_DIVIDE(
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)),
    COUNT(DISTINCT user_pseudo_id)) * 100, 2)                            AS cvr_pct
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
GROUP BY country, region
HAVING users >= 100
ORDER BY revenue DESC
LIMIT 50;


-- ============================================================================
-- 7. TOP PAGES
-- page_location is a key inside event_params, not a column. This is the
-- correct extraction pattern for any event parameter.
-- ============================================================================

SELECT
  (SELECT value.string_value FROM UNNEST(event_params)
   WHERE key = 'page_location')  AS page_location,
  COUNT(*)                       AS pageviews,
  COUNT(DISTINCT user_pseudo_id) AS unique_viewers
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
  AND event_name = 'page_view'
GROUP BY page_location
ORDER BY pageviews DESC
LIMIT 25;


-- ============================================================================
-- 8. SESSIONS TO PURCHASE (path length)
-- A genuine multi-touch signal that IS available: how many sessions a buyer
-- needed before converting. If most buyers convert in session 1, single-touch
-- attribution is fine. If not, you need multi-touch.
-- ============================================================================

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params)
     WHERE key = 'ga_session_id')                       AS session_id,
    MIN(event_timestamp)                               AS session_start_us,
    MAX(IF(event_name = 'purchase', 1, 0))             AS had_purchase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
  GROUP BY user_pseudo_id, session_id
),
numbered AS (
  SELECT
    user_pseudo_id,
    had_purchase,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id
                       ORDER BY session_start_us) AS session_number
  FROM sessions
)
SELECT
  session_number,
  COUNT(*)                                             AS sessions,
  SUM(had_purchase)                                    AS sessions_with_purchase,
  ROUND(SAFE_DIVIDE(SUM(had_purchase), COUNT(*)) * 100, 2) AS purchase_rate_pct
FROM numbered
WHERE session_number <= 10
GROUP BY session_number
ORDER BY session_number;


-- ============================================================================
-- 9. FIRST-TOUCH vs LAST-TOUCH ATTRIBUTION — IMPORTANT CAVEAT
-- ============================================================================
--
-- This CANNOT be done with the traffic_source field, and the earlier version
-- of this file was wrong to try.
--
-- traffic_source in the GA4 export is USER-SCOPED: it records the user's very
-- first acquisition source and repeats that same value on every one of their
-- events, forever. First-touch and last-touch computed from it are identical
-- by construction. Any "comparison" between them is meaningless.
--
-- Real multi-touch attribution needs EVENT-SCOPED source data, which lives in:
--
--   collected_traffic_source.manual_campaign_name
--   collected_traffic_source.manual_source
--   collected_traffic_source.manual_medium
--   collected_traffic_source.gclid
--   session_traffic_source_last_click.*
--
-- Those fields were added to the export in 2023. They do NOT exist in the 2020
-- to 2021 public sample, so the query below will error against it. Run it only
-- against your own export.
--
-- Uncomment and point at your own dataset when ready:
--
-- WITH session_sources AS (
--   SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params)
--      WHERE key = 'ga_session_id')                          AS session_id,
--     MIN(event_timestamp)                                   AS session_start_us,
--     ANY_VALUE(collected_traffic_source.manual_source)      AS source,
--     ANY_VALUE(collected_traffic_source.manual_medium)      AS medium,
--     ANY_VALUE(collected_traffic_source.manual_campaign_name) AS campaign,
--     MAX(IF(event_name = 'purchase', 1, 0))                 AS converted,
--     SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue, 0)) AS revenue
--   FROM `project-f3310b3f-c096-49d1-a35.analytics_547243036.events_*`
--   WHERE _TABLE_SUFFIX BETWEEN '20260701' AND '20260731'
--   GROUP BY user_pseudo_id, session_id
-- ),
-- converters AS (
--   SELECT
--     user_pseudo_id,
--     FIRST_VALUE(campaign) OVER w AS first_touch_campaign,
--     LAST_VALUE(campaign)  OVER w AS last_touch_campaign,
--     SUM(revenue) OVER (PARTITION BY user_pseudo_id) AS user_revenue
--   FROM session_sources
--   WINDOW w AS (
--     PARTITION BY user_pseudo_id ORDER BY session_start_us
--     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--   )
-- )
-- SELECT
--   first_touch_campaign,
--   last_touch_campaign,
--   COUNT(DISTINCT user_pseudo_id) AS users,
--   ROUND(SUM(user_revenue), 2)    AS revenue
-- FROM converters
-- GROUP BY first_touch_campaign, last_touch_campaign
-- ORDER BY revenue DESC;


-- ============================================================================
-- 10. JOINING GOOGLE ADS SPEND TO GA4 REVENUE — WHAT'S ACTUALLY REQUIRED
-- ============================================================================
--
-- The earlier version queried a `campaign` table with metrics.cost_micros from
-- inside the GA4 dataset. That table does not exist there.
--
-- Google Ads data reaches BigQuery through a separate mechanism: BigQuery Data
-- Transfer Service (Transfers > Create Transfer > Google Ads). It lands in its
-- own dataset with tables like ads_Campaign_<customer_id> and
-- ads_CampaignBasicStats_<customer_id>.
--
-- That transfer requires an approved developer token with Basic access at
-- minimum — the same approval currently blocking your Python scripts. Until
-- then, there is no Ads spend in BigQuery to join to.
--
-- The join key is campaign name, matched to GA4's manual_campaign_name (or,
-- more reliably, gclid). Shape of it once both sides exist:
--
-- WITH ads AS (
--   SELECT
--     campaign_name,
--     SUM(metrics_cost_micros) / 1000000 AS spend
--   FROM `PROJECT.ADS_DATASET.ads_CampaignBasicStats_XXXXXXXXXX`
--   WHERE _DATA_DATE BETWEEN '2026-07-01' AND '2026-07-31'
--   GROUP BY campaign_name
-- ),
-- ga4 AS (
--   SELECT
--     collected_traffic_source.manual_campaign_name AS campaign_name,
--     SUM(ecommerce.purchase_revenue)               AS revenue,
--     COUNT(DISTINCT ecommerce.transaction_id)      AS transactions
--   FROM `PROJECT.analytics_547243036.events_*`
--   WHERE _TABLE_SUFFIX BETWEEN '20260701' AND '20260731'
--     AND event_name = 'purchase'
--   GROUP BY campaign_name
-- )
-- SELECT
--   COALESCE(ads.campaign_name, ga4.campaign_name) AS campaign,
--   ROUND(ads.spend, 2)                            AS ad_spend,
--   ROUND(ga4.revenue, 2)                          AS ga4_revenue,
--   ga4.transactions,
--   ROUND(SAFE_DIVIDE(ga4.revenue, ads.spend), 2)  AS true_roas
-- FROM ads
-- FULL OUTER JOIN ga4 USING (campaign_name)
-- ORDER BY ad_spend DESC;
--
-- A FULL OUTER JOIN is deliberate: campaigns with spend and no revenue are the
-- most important rows in the report, and an INNER JOIN would hide them.


-- ============================================================================
-- WHAT WILL RETURN ZERO ON YOUR OWN PROPERTY, AND WHY
-- ============================================================================
--
-- Your property (547243036) currently reports roughly 166 events and 0 key
-- events. That means it is firing automatic events only — page_view,
-- session_start, first_visit, user_engagement.
--
-- Consequently, on your own export:
--   Query 0    works, and will show you exactly which events you have
--   Query 4    works (users, sessions)
--   Query 5, 6 work for users, but purchasers and revenue will be 0
--   Query 7    works
--   Query 8    works, though with few users the rates are noisy
--   Query 1-3  return rows, but every ecommerce column will be 0 or NULL
--
-- To get non-zero revenue you need a real site sending purchase events with
-- ecommerce parameters. Until then, keep developing the revenue and ROAS
-- queries against the public sample, and be explicit in your README that the
-- ecommerce analysis is demonstrated on Google's sample dataset rather than on
-- live data. That distinction is worth stating plainly — reviewers notice it,
-- and being upfront reads far better than appearing to claim live revenue.
-- ============================================================================
