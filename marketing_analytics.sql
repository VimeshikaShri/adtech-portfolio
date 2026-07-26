-- ================================================================
-- ADTECH PORTFOLIO - BIGQUERY MARKETING ANALYTICS
-- Comprehensive SQL Queries for Google Ads Campaign Analysis
-- ================================================================

-- =================================================================
-- 1. CAMPAIGN PERFORMANCE SUMMARY
-- =================================================================

-- Daily Campaign Summary with Key Metrics
SELECT
  segments.date,
  campaign.id,
  campaign.name,
  ROUND(SUM(metrics.impressions), 0) as impressions,
  ROUND(SUM(metrics.clicks), 0) as clicks,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as spend_usd,
  ROUND(SUM(metrics.conversions), 0) as conversions,
  ROUND(SUM(metrics.conversion_value), 2) as revenue,
  ROUND(SUM(metrics.clicks) / SUM(metrics.impressions) * 100, 2) as ctr_percent,
  ROUND(SUM(metrics.cost_micros) / 1000000 / NULLIF(SUM(metrics.clicks), 0), 2) as avg_cpc,
  ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.cost_micros) / 1000000, 0), 2) as roas,
  ROUND(SUM(metrics.cost_micros) / 1000000 / NULLIF(SUM(metrics.conversions), 0), 2) as cpa
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY
  segments.date,
  campaign.id,
  campaign.name
ORDER BY
  segments.date DESC,
  spend_usd DESC;

-- Rolling 7-Day Campaign Performance
SELECT
  campaign.name,
  CURRENT_DATE() as report_date,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as spend_7d,
  ROUND(SUM(metrics.conversion_value), 2) as revenue_7d,
  ROUND(SUM(metrics.conversions), 0) as conversions_7d,
  ROUND(SUM(metrics.clicks), 0) as clicks_7d,
  ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.cost_micros) / 1000000, 0), 2) as roas_7d,
  ROUND(SUM(metrics.cost_micros) / 1000000 / NULLIF(SUM(metrics.conversions), 0), 2) as cpa_7d
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND CURRENT_DATE()
GROUP BY
  campaign.name
ORDER BY
  roas_7d DESC;

-- Monthly Budget Efficiency
SELECT
  EXTRACT(YEAR FROM segments.date) as year,
  EXTRACT(MONTH FROM segments.date) as month,
  campaign.name,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as monthly_spend,
  ROUND(SUM(metrics.conversion_value), 2) as monthly_revenue,
  ROUND(SUM(metrics.conversions), 0) as monthly_conversions,
  ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.cost_micros) / 1000000, 0), 2) as roas,
  ROUND(SUM(metrics.cost_micros) / 1000000 / NULLIF(SUM(metrics.conversions), 0), 2) as cpa
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY
  year, month, campaign.name
ORDER BY
  year DESC, month DESC, roas DESC;

-- =================================================================
-- 2. KEYWORD ANALYSIS & OPTIMIZATION
-- =================================================================

-- Top Performing Keywords by ROAS
SELECT
  ad_group_criterion.keyword.text as keyword,
  ad_group.name,
  campaign.name,
  ROUND(SUM(metrics.impressions), 0) as impressions,
  ROUND(SUM(metrics.clicks), 0) as clicks,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as spend,
  ROUND(SUM(metrics.conversions), 0) as conversions,
  ROUND(SUM(metrics.conversion_value), 2) as revenue,
  ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.cost_micros) / 1000000, 0), 2) as roas,
  ROUND(SUM(metrics.cost_micros) / 1000000 / NULLIF(SUM(metrics.clicks), 0), 2) as avg_cpc
FROM
  `{project_id}.{dataset_id}.keyword_view`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ad_group_criterion.status = 'ENABLED'
GROUP BY
  keyword,
  ad_group.name,
  campaign.name
HAVING
  SUM(metrics.clicks) >= 10  -- At least 10 clicks for reliability
ORDER BY
  roas DESC
LIMIT 50;

-- Underperforming Keywords (Pause Candidates)
SELECT
  ad_group_criterion.keyword.text as keyword,
  ad_group.name,
  campaign.name,
  ROUND(SUM(metrics.clicks), 0) as clicks,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as spend,
  ROUND(SUM(metrics.conversions), 0) as conversions,
  ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.cost_micros) / 1000000, 0), 2) as roas,
  'PAUSE' as recommendation
FROM
  `{project_id}.{dataset_id}.keyword_view`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ad_group_criterion.status = 'ENABLED'
GROUP BY
  keyword,
  ad_group.name,
  campaign.name
HAVING
  SUM(metrics.conversions) = 0  -- No conversions
  AND SUM(metrics.clicks) >= 20  -- But has traffic
ORDER BY
  spend DESC
LIMIT 50;

-- Keyword Bid Optimization Opportunities
SELECT
  ad_group_criterion.keyword.text as keyword,
  campaign.name,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as spend_30d,
  ROUND(SUM(metrics.conversions), 0) as conversions_30d,
  ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.cost_micros) / 1000000, 0), 2) as roas,
  CASE
    WHEN ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.cost_micros) / 1000000, 0), 2) >= 4.0 THEN 'INCREASE BID'
    WHEN ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.cost_micros) / 1000000, 0), 2) >= 2.0 THEN 'MAINTAIN'
    ELSE 'DECREASE BID'
  END as bid_recommendation
FROM
  `{project_id}.{dataset_id}.keyword_view`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ad_group_criterion.status = 'ENABLED'
GROUP BY
  keyword,
  campaign.name
HAVING
  SUM(metrics.clicks) >= 5
ORDER BY
  roas DESC;

-- =================================================================
-- 3. ATTRIBUTION & CONVERSION ANALYSIS
-- =================================================================

-- Last Non-Direct Click Attribution
SELECT
  campaign.name,
  ROUND(SUM(metrics.conversions), 0) as total_conversions,
  ROUND(SUM(metrics.conversion_value), 2) as total_conversion_value,
  ROUND(SUM(metrics.conversion_value) / NULLIF(SUM(metrics.conversions), 0), 2) as avg_conversion_value,
  ROUND(COUNT(DISTINCT segments.date), 0) as days_with_conversions
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  AND campaign.status = 'ENABLED'
GROUP BY
  campaign.name
ORDER BY
  total_conversion_value DESC;

-- Top 20 Conversion Paths
SELECT
  campaign.name,
  ad_group.name,
  ROUND(SUM(metrics.conversions), 0) as conversions,
  ROUND(SUM(metrics.conversion_value), 2) as value,
  ROUND(AVG(metrics.conversion_value), 2) as avg_value_per_conversion
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
GROUP BY
  campaign.name,
  ad_group.name
ORDER BY
  conversions DESC
LIMIT 20;

-- Conversion Rate by Campaign
SELECT
  campaign.name,
  ROUND(SUM(metrics.impressions), 0) as impressions,
  ROUND(SUM(metrics.clicks), 0) as clicks,
  ROUND(SUM(metrics.conversions), 0) as conversions,
  ROUND(SUM(metrics.clicks) / SUM(metrics.impressions) * 100, 2) as ctr_percent,
  ROUND(SUM(metrics.conversions) / SUM(metrics.clicks) * 100, 2) as conversion_rate_percent,
  ROUND(SUM(metrics.conversions) / SUM(metrics.impressions) * 100, 4) as conv_rate_impressions
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY
  campaign.name
ORDER BY
  conversion_rate_percent DESC;

-- =================================================================
-- 4. BUDGET FORECASTING & PACING
-- =================================================================

-- Daily Budget Pacing Analysis
SELECT
  CURRENT_DATE() as report_date,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as today_spend,
  ROUND(AVG(CASE WHEN segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) 
                 THEN metrics.cost_micros / 1000000 END), 2) as avg_daily_spend_7d,
  ROUND(AVG(CASE WHEN segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) 
                 THEN metrics.cost_micros / 1000000 END), 2) as avg_daily_spend_30d,
  ROUND(AVG(CASE WHEN segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) 
                 THEN metrics.cost_micros / 1000000 END) * 30, 2) as projected_monthly
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- 7-Day Spending Forecast
SELECT
  DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY) as forecast_date,
  ROUND(AVG(CASE WHEN segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) 
                 THEN metrics.cost_micros / 1000000 END), 2) as forecasted_daily_spend,
  ROUND(AVG(CASE WHEN segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) 
                 THEN metrics.cost_micros / 1000000 END) * 7, 2) as forecasted_7d_spend
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  campaign.status = 'ENABLED';

-- 90-Day ROI Projection
SELECT
  campaign.name,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as spend_90d,
  ROUND(SUM(metrics.conversion_value), 2) as revenue_90d,
  ROUND(SUM(metrics.conversion_value) / SUM(metrics.cost_micros) * 1000000, 2) as roas_90d,
  ROUND((SUM(metrics.conversion_value) - SUM(metrics.cost_micros) / 1000000), 2) as net_profit,
  ROUND((SUM(metrics.conversion_value) - SUM(metrics.cost_micros) / 1000000) / 
        SUM(metrics.cost_micros) * 1000000 * 100, 2) as roi_percent
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  AND campaign.status = 'ENABLED'
GROUP BY
  campaign.name
ORDER BY
  roi_percent DESC;

-- =================================================================
-- 5. COHORT ANALYSIS
-- =================================================================

-- Weekly Cohort Retention
SELECT
  DATE_TRUNC(segments.date, WEEK) as cohort_week,
  ROUND(COUNT(DISTINCT segments.date), 0) as active_days,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as weekly_spend,
  ROUND(SUM(metrics.conversions), 0) as weekly_conversions,
  ROUND(SUM(metrics.conversion_value), 2) as weekly_value
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
GROUP BY
  cohort_week
ORDER BY
  cohort_week DESC;

-- Lifetime Value by Acquisition Cohort
SELECT
  DATE_TRUNC(segments.date, MONTH) as cohort_month,
  ROUND(SUM(metrics.conversion_value), 2) as total_ltv,
  ROUND(SUM(metrics.conversions), 0) as total_customers,
  ROUND(SUM(metrics.conversion_value) / SUM(metrics.conversions), 2) as avg_customer_value,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as cac_total,
  ROUND(SUM(metrics.cost_micros) / 1000000 / SUM(metrics.conversions), 2) as cac_per_customer
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
GROUP BY
  cohort_month
ORDER BY
  cohort_month DESC;

-- =================================================================
-- 6. ADVANCED KPI CALCULATIONS
-- =================================================================

-- Blended ROAS Across All Campaigns
SELECT
  CURRENT_DATE() as report_date,
  ROUND(SUM(metrics.conversion_value), 2) as total_revenue,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as total_spend,
  ROUND(SUM(metrics.conversion_value) / (SUM(metrics.cost_micros) / 1000000), 2) as blended_roas,
  ROUND(SUM(metrics.conversions), 0) as total_conversions,
  ROUND((SUM(metrics.cost_micros) / 1000000) / SUM(metrics.conversions), 2) as blended_cpa,
  ROUND(SUM(metrics.clicks), 0) as total_clicks,
  ROUND((SUM(metrics.cost_micros) / 1000000) / SUM(metrics.clicks), 2) as avg_cpc
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date = CURRENT_DATE();

-- CAC Payback Period Analysis
SELECT
  campaign.name,
  ROUND(SUM(metrics.cost_micros) / 1000000 / SUM(metrics.conversions), 2) as cac,
  ROUND(SUM(metrics.conversion_value) / SUM(metrics.conversions), 2) as avg_customer_ltv,
  ROUND((SUM(metrics.cost_micros) / 1000000 / SUM(metrics.conversions)) / 
        (SUM(metrics.conversion_value) / SUM(metrics.conversions)), 2) as payback_months
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  AND campaign.status = 'ENABLED'
GROUP BY
  campaign.name
ORDER BY
  payback_months ASC;

-- Customer Segment Analysis
SELECT
  campaign.name,
  ROUND(SUM(metrics.cost_micros) / 1000000, 2) as segment_spend,
  ROUND(SUM(metrics.conversions), 0) as segment_customers,
  ROUND(SUM(metrics.conversion_value), 2) as segment_revenue,
  ROUND(SUM(metrics.cost_micros) / 1000000 / SUM(metrics.conversions), 2) as segment_cac,
  ROUND(SUM(metrics.conversion_value) / SUM(metrics.conversions), 2) as segment_ltv,
  CASE
    WHEN SUM(metrics.conversion_value) / (SUM(metrics.cost_micros) / 1000000) >= 4 THEN 'HIGH_VALUE'
    WHEN SUM(metrics.conversion_value) / (SUM(metrics.cost_micros) / 1000000) >= 2 THEN 'MEDIUM_VALUE'
    ELSE 'LOW_VALUE'
  END as segment_tier
FROM
  `{project_id}.{dataset_id}.campaign`
WHERE
  segments.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
GROUP BY
  campaign.name
ORDER BY
  segment_revenue DESC;

-- =================================================================
-- NOTES
-- =================================================================
-- Replace {project_id} with your Google Cloud project ID
-- Replace {dataset_id} with your BigQuery dataset name
-- These queries work with Google Ads data transferred to BigQuery
-- Adjust date ranges based on your analysis needs
