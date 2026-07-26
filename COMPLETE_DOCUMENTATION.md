# AdTech Portfolio - Complete Documentation 📚

Comprehensive documentation for the AdTech portfolio project.

---

## 📖 Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Configuration](#configuration)
3. [Scripts & APIs](#scripts--apis)
4. [SQL Queries](#sql-queries)
5. [Dashboards](#dashboards)
6. [Troubleshooting](#troubleshooting)
7. [FAQ](#faq)
8. [Best Practices](#best-practices)

---

## 🚀 Installation & Setup

### System Requirements

```
Python: 3.9+
OS: Mac, Linux, or Windows
RAM: 2GB minimum
Internet: Required for Google APIs
```

### Step 1: Clone Repository

```bash
git clone https://github.com/VimeshikaShri/adtech-portfolio.git
cd adtech-portfolio
```

### Step 2: Create Virtual Environment

```bash
# Mac/Linux
python3 -m venv venv
source venv/bin/activate

# Windows
python -m venv venv
venv\Scripts\activate
```

### Step 3: Install Dependencies

```bash
pip install -r requirements.txt
```

### Step 4: Setup Credentials

```bash
# Copy example config
cp config.example.yaml config.yaml
cp google-ads.yaml.example google-ads.yaml

# Edit with your credentials
nano config.yaml
nano google-ads.yaml
```

---

## ⚙️ Configuration

### config.yaml Structure

```yaml
google_ads:
  developer_token: "your_token"
  client_id: "your_client_id"
  client_secret: "your_client_secret"
  refresh_token: "your_refresh_token"
  customer_id: "your_customer_id"  # Without dashes

bidding_strategy:
  daily_budget_usd: 15000.00      # Your daily budget
  roas_target: 3.5                # Target return on ad spend
  cpa_target: 12.50               # Target cost per acquisition
  min_bid_micros: 100000          # $0.10 minimum
  max_bid_micros: 5000000         # $5.00 maximum
  daily_bid_adjustment_percent: 5 # ±5% per day

budget_monitor:
  check_interval_minutes: 60      # Check every hour
  alert_overspend_percent: 110    # Alert at 110% of budget
  alert_underspend_percent: 50    # Alert at 50% of budget

slack:
  enabled: true
  webhook_url: "your_slack_webhook"
  alert_channel: "#marketing-alerts"

logging:
  level: "INFO"
  log_file: "logs/adtech.log"
```

### Getting Credentials

#### Google Ads Developer Token
1. Go to: https://ads.google.com/aw/apicenter
2. Request Developer Token
3. Wait for approval (24 hours)
4. Copy token

#### OAuth Credentials
1. Go to: https://console.cloud.google.com
2. Create Project
3. Enable Google Ads API
4. Create OAuth 2.0 Credentials
5. Get Client ID & Secret

#### Refresh Token
1. Use OAuth Playground: https://developers.google.com/oauthplayground
2. Authorize with your Google account
3. Exchange code for tokens
4. Copy Refresh Token

#### Customer ID
1. Go to: https://ads.google.com
2. Click Settings
3. Find Customer ID (XXX-XXX-XXXX)
4. Remove dashes for config

---

## 📜 Scripts & APIs

### budget_monitor.py

**Purpose:** Monitor daily budget spending and alert on overspends

**Usage:**
```bash
# Run once
python scripts/budget_monitor.py --config config.yaml --once

# Run continuously
python scripts/budget_monitor.py --config config.yaml
```

**Features:**
- Real-time budget tracking
- Campaign-level breakdown
- Slack notifications
- Dry-run mode
- Logging

**Output:**
```
📊 Daily Budget Report - 2026-07-25
============================================================

BUDGET METRICS:
Total Spend:       $4,234.56 / $15,000.00
Budget Pace:       28.2%
Status:            🟩 ON_TRACK

CAMPAIGN BREAKDOWN:
1. Summer Sale              | $1,856.34 | 456 clicks
2. Brand Campaign           | $1,432.12 | 567 clicks
```

**Configuration Parameters:**
```yaml
daily_budget_usd: 15000.00       # Your daily budget
alert_overspend_percent: 110     # Alert threshold
alert_underspend_percent: 50     # Low spend alert
check_interval_minutes: 60       # How often to check
```

### automated_bidding_strategy.py

**Purpose:** Optimize bids based on ROAS and CPA

**Usage:**
```bash
# Test (dry-run)
python scripts/automated_bidding_strategy.py --config config.yaml --dry-run

# Apply changes
python scripts/automated_bidding_strategy.py --config config.yaml
```

**Features:**
- ROAS-based bid adjustment
- CPA enforcement
- Keyword pausing
- Audit logging
- Email alerts

**Bid Adjustment Rules:**
```python
if roas >= target:
    increase_bid(5%)  # Increase by 5% per day max
elif roas < 1.5 * target:
    decrease_bid(3%)  # Decrease by 3% per day max
else:
    maintain_bid()    # Keep current bid

if roas < pause_threshold:
    pause_keyword()   # Pause low ROAS keywords
```

**Configuration Parameters:**
```yaml
roas_target: 3.5                 # Target ROAS
cpa_target: 12.50                # Target CPA
pause_below_roas: 1.0            # Pause threshold
daily_bid_adjustment_percent: 5  # Max adjustment
```

### utils.py

**Purpose:** Helper functions and utilities

**Key Classes:**

```python
class MetricsCalculator:
    - calculate_roas()
    - calculate_cpa()
    - calculate_roi()

class BudgetForecaster:
    - forecast_daily_spend()
    - forecast_monthly_spend()
    - predict_overspend()

class BidOptimizer:
    - calculate_new_bid()
    - should_pause_keyword()
    - apply_bid_changes()

class ReportGenerator:
    - generate_daily_report()
    - generate_campaign_summary()
    - create_performance_report()

class SlackFormatter:
    - format_budget_alert()
    - format_performance_update()
    - send_notification()
```

---

## 🔍 SQL Queries

### Location
```
sql_queries/comprehensive_marketing_analytics.sql
```

### Query Categories

**1. Campaign Performance (Lines 1-100)**
- Daily campaign summary
- Rolling 7-day averages
- Monthly budget efficiency
- Campaign rankings by ROAS

**2. Keyword Analysis (Lines 101-200)**
- Top performers by ROAS
- Underperforming keywords (pause candidates)
- Bid optimization opportunities
- Keyword trend analysis

**3. Attribution (Lines 201-300)**
- Last non-direct click conversion attribution
- Top conversion paths
- Conversion rate by campaign
- Customer journey analysis

**4. Budget Forecasting (Lines 301-400)**
- Daily pacing analysis
- 7-day spending forecast
- 90-day ROI projection
- Monthly trend analysis

**5. Cohort Analysis (Lines 401-500)**
- Weekly retention analysis
- Lifetime value by cohort
- Customer acquisition cohorts
- Retention curves

**6. Advanced KPIs (Lines 501-600)**
- Blended ROAS calculation
- CAC payback period
- Customer segment analysis
- Custom metric definitions

### Running Queries

**In BigQuery Console:**
```sql
-- Replace placeholders
-- {project_id} = your-project-id
-- {dataset_id} = your-dataset-name

-- Copy query and run in BigQuery
-- Results can be exported to CSV/Sheet
```

**In Python:**
```python
from google.cloud import bigquery

client = bigquery.Client()
query = """
  SELECT campaign.name, SUM(metrics.cost_micros)
  FROM `{project}.{dataset}.campaign`
  GROUP BY campaign.name
"""
results = client.query(query).result()
for row in results:
    print(row)
```

---

## 📊 Dashboards

### Dashboard 1: Budget Pacing
**File:** `dashboards/DASHBOARD_SETUP.md`

**Components:**
- Today's budget pace (scorecard)
- Daily spend vs. budget (line chart)
- Campaign breakdown (pie chart)
- Budget pace table
- Monthly forecast

**Update Frequency:** Real-time
**Audience:** Managers, team leads

### Dashboard 2: Campaign Performance
**Components:**
- Campaign summary table
- ROAS trend (line chart)
- CPA trend (line chart)
- Performance heatmap
- Status cards

**Update Frequency:** Daily
**Audience:** Campaign managers, analysts

### Dashboard 3: Keywords & Ad Groups
**Components:**
- Top keywords table
- Pause candidates
- Bid opportunity matrix
- Performance scorecard
- Keyword trends

**Update Frequency:** Daily
**Audience:** PPC specialists, optimizers

### Dashboard 4: ROI & Profitability
**Components:**
- Key metrics summary
- Revenue vs. spend trend
- ROAS by campaign
- Profitability table
- Conversion funnel

**Update Frequency:** Daily
**Audience:** Executives, finance, management

---

## 🆘 Troubleshooting

### Common Issues

#### 1. "Authentication Failed"
**Problem:** Google credentials not working
**Solution:**
```bash
# Verify credentials file
cat google-ads.yaml

# Check file format
# developer_token, client_id, client_secret, refresh_token

# Regenerate if needed
python get_refresh_token.py
```

#### 2. "Budget Monitoring Not Working"
**Problem:** Script runs but shows no data
**Solution:**
```bash
# Check internet connection
ping google.com

# Verify API is enabled
# https://console.cloud.google.com/apis/enabled

# Check customer ID format (no dashes)
grep customer_id config.yaml
```

#### 3. "Slack Notifications Not Sending"
**Problem:** No alerts in Slack
**Solution:**
```bash
# Verify webhook URL
grep webhook_url config.yaml

# Test webhook manually
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"test"}' \
  YOUR_WEBHOOK_URL
```

#### 4. "BigQuery Queries Failing"
**Problem:** SQL errors or no results
**Solution:**
```bash
# Verify dataset exists
# Replace placeholders in queries

# Test simple query
SELECT 1 as test

# Check table names
# campaign, ad_group, keyword_view

# Verify date format
# segments.date (YYYY-MM-DD)
```

### Getting Help

**Check Logs:**
```bash
tail -f logs/adtech.log
```

**Enable Debug Logging:**
```yaml
# In config.yaml
logging:
  level: "DEBUG"
```

**Common Log Messages:**
```
INFO - Running budget monitor
ERROR - Error fetching budget data
WARNING - API rate limit approaching
DEBUG - Request payload details
```

---

## ❓ FAQ

### Q: How often should I run the scripts?
**A:** 
- Budget Monitor: Every hour (automatic)
- Bidding Strategy: Once daily (early morning)
- Reports: Daily/weekly (scheduled)

### Q: What ROAS target should I use?
**A:** Depends on your margins:
- Luxury goods: 3.0x - 5.0x
- Electronics: 2.5x - 3.5x
- Consumables: 2.0x - 3.0x
- B2B Services: 1.5x - 3.0x

### Q: How to handle testing accounts?
**A:**
```bash
# Use separate config
cp config.yaml config.test.yaml
# Edit customer ID to test account
python scripts/budget_monitor.py --config config.test.yaml --once
```

### Q: Can I run multiple campaigns simultaneously?
**A:** Yes, with separate customer IDs:
```yaml
# Create config for each
config.campaign1.yaml
config.campaign2.yaml

# Run in background
nohup python scripts/budget_monitor.py --config config.campaign1.yaml &
nohup python scripts/budget_monitor.py --config config.campaign2.yaml &
```

### Q: How to automate script execution?
**A:** Use cron jobs (Mac/Linux):
```bash
# Edit crontab
crontab -e

# Add jobs
0 * * * * cd ~/adtech-portfolio && python scripts/budget_monitor.py --config config.yaml
0 6 * * * cd ~/adtech-portfolio && python scripts/automated_bidding_strategy.py --config config.yaml
0 7 * * * cd ~/adtech-portfolio && python scripts/report_generator.py
```

### Q: How to monitor multiple Google Ads accounts?
**A:** Use manager account:
```yaml
google_ads:
  customer_id: "123-456-7890"  # Manager account
  # Automatically see all linked accounts
```

---

## 💡 Best Practices

### 1. Credential Management
✅ DO:
- Keep credentials in config.yaml (local only)
- Add config.yaml to .gitignore
- Use environment variables in production
- Rotate tokens regularly

❌ DON'T:
- Share credentials via email
- Commit config.yaml to GitHub
- Hardcode credentials in scripts
- Use same token for multiple projects

### 2. Script Execution
✅ DO:
- Test with --dry-run first
- Check logs before running live
- Monitor first execution manually
- Schedule during low-traffic hours

❌ DON'T:
- Run multiple scripts simultaneously (rate limits)
- Make large bid changes without testing
- Run scripts during campaigns
- Ignore error messages

### 3. Dashboard Management
✅ DO:
- Review dashboards daily
- Set up alerts for anomalies
- Share with relevant team members
- Archive old dashboards

❌ DON'T:
- Ignore red metrics
- Make decisions without checking data
- Share sensitive dashboards externally
- Mix test and live data

### 4. Performance Optimization
✅ DO:
- Cache API responses
- Batch API calls
- Use BigQuery for analysis
- Monitor API usage

❌ DON'T:
- Call API for every operation
- Run queries on entire datasets
- Ignore rate limits
- Leave debug logging on

### 5. Security
✅ DO:
- Use OAuth 2.0
- Encrypt sensitive data
- Audit access regularly
- Update dependencies

❌ DON'T:
- Use hardcoded passwords
- Share refresh tokens
- Allow unauthorized access
- Ignore security warnings

---

## 📈 Performance Tuning

### Script Optimization

```python
# Good: Batch requests
keywords = get_all_keywords()
bids = calculate_new_bids(keywords)  # Single operation

# Bad: Loop with API calls
for keyword in keywords:
    bid = calculate_bid(keyword)      # Multiple API calls
```

### Query Optimization

```sql
-- Good: Single query
SELECT campaign, SUM(cost) FROM campaign GROUP BY campaign

-- Bad: Multiple queries in loop
SELECT SUM(cost) FROM campaign WHERE campaign_id = 1
SELECT SUM(cost) FROM campaign WHERE campaign_id = 2
```

### Memory Management

```python
# Good: Stream results
for row in client.query(query).result():
    process(row)

# Bad: Load all into memory
results = list(client.query(query).result())
for row in results:
    process(row)
```

---

## 📞 Support & Resources

**Documentation:**
- [Google Ads API](https://developers.google.com/google-ads/api)
- [BigQuery SQL Reference](https://cloud.google.com/bigquery/docs/reference/standard-sql)
- [Looker Studio Help](https://support.google.com/datastudio)

**Community:**
- Stack Overflow (tag: google-ads-api)
- Google Ads API Community
- Python Community Forums

**Contact:**
- GitHub Issues: Report bugs
- GitHub Discussions: Ask questions
- Email: vimeshika.balamurali@gmail.com

---

## ✅ Checklist

- [ ] Installation complete
- [ ] Credentials configured
- [ ] Scripts tested
- [ ] Dashboards created
- [ ] SQL queries working
- [ ] Automated scheduling set up
- [ ] Team trained
- [ ] Monitoring in place
- [ ] Documentation reviewed
- [ ] Backups configured

---

**Last Updated:** 2026-07-25
**Version:** 1.0.0
**Maintainer:** Vimeshika Shri

---

**For latest updates, check:** https://github.com/VimeshikaShri/adtech-portfolio
