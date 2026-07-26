# Dashboard Setup Guide - Looker Studio 📊

Complete guide to creating professional marketing dashboards in Google Looker Studio.

---

## 🎯 Prerequisites

- ✅ Google Account
- ✅ Google Looker Studio access (free)
- ✅ BigQuery dataset with Google Ads data
- ✅ Access to marketing analytics SQL queries

---

## 🚀 Quick Start

### Step 1: Create New Looker Studio Report

1. Go to: https://datastudio.google.com
2. Click **"Create"** → **"Report"**
3. Name: "Marketing Analytics Dashboard"
4. Click **"Create"**

---

### Step 2: Connect BigQuery Data Source

1. Click **"Create new data source"**
2. Select **"BigQuery"**
3. **Project:** Select your Google Cloud project
4. **Dataset:** Select your marketing analytics dataset
5. **Table:** Select your campaign table
6. Click **"Create"**

---

## 📊 Dashboard 1: Budget Pacing

### Purpose
Monitor daily budget spending and forecast overspends.

### Components

#### 1. Today's Budget Pace (Scorecard)
```
Metric: SUM(cost_micros) / 1000000
Filter: Date = TODAY()
Comparison: Previous Period

Shows:
- Current day spend
- vs. average daily spend
- Status indicator
```

#### 2. Daily Spend vs. Budget (Line Chart)
```
Dimension: Date
Metrics:
- SUM(cost_micros) / 1000000 as Spend
- Budget Target (constant line)

Time Range: Last 30 days
Shows spending trend and budget threshold
```

#### 3. Campaign Budget Breakdown (Pie Chart)
```
Dimension: Campaign Name
Metric: SUM(cost_micros) / 1000000
Filter: Date >= 30 days ago

Shows allocation of budget across campaigns
```

#### 4. Budget Pace Table (Table)
```
Dimensions: Campaign Name, Date
Metrics:
- SUM(cost_micros) / 1000000 as Daily_Spend
- AVG(cost_micros) / 1000000 as Avg_Daily
- Percentage of Budget

Sorting: Date DESC, Spend DESC
```

#### 5. Forecast Widget (Scorecard)
```
Metric: AVG(cost_micros where date >= 30 days) * 30
Text: "Projected Monthly Spend"
Comparison: Target Budget
```

---

## 📈 Dashboard 2: Campaign Performance

### Purpose
Monitor campaign metrics and performance trends.

### Components

#### 1. Campaign Summary (Table)
```
Dimensions:
- Campaign Name

Metrics:
- SUM(impressions)
- SUM(clicks)
- SUM(cost_micros) / 1000000
- SUM(conversions)
- SUM(conversion_value)
- ROAS = conversion_value / cost * 1000000
- CPA = cost / conversions * 1000000
- CTR = clicks / impressions * 100

Filter: Date >= 30 days ago
Sorting: ROAS DESC
```

#### 2. ROAS Trend (Line Chart)
```
Dimension: Date
Metric: SUM(conversion_value) / (SUM(cost) / 1000000)
Breakdown: Campaign Name

Comparison line: Target ROAS (3.5x)
Shows ROAS trend over time by campaign
```

#### 3. CPA Trend (Line Chart)
```
Dimension: Date
Metric: SUM(cost) / SUM(conversions) / 1000000
Breakdown: Campaign Name

Comparison line: Target CPA ($12.50)
Shows cost per acquisition trend
```

#### 4. Campaign Status Cards
```
Scorecard Cards (4):
1. Top Campaign by ROAS
2. Top Campaign by Spend
3. Top Campaign by Conversions
4. Average ROAS (All Campaigns)
```

#### 5. Performance Heatmap (Table)
```
Rows: Campaign Name
Columns: Week
Values: ROAS

Color scale:
- Red: < 2.0x
- Yellow: 2.0 - 3.5x
- Green: > 3.5x
```

---

## 🎯 Dashboard 3: Keywords & Ad Groups

### Purpose
Identify top performers and optimization opportunities.

### Components

#### 1. Top Keywords (Table)
```
Dimensions:
- Keyword Text
- Ad Group Name
- Campaign Name

Metrics:
- SUM(clicks)
- SUM(cost) / 1000000
- SUM(conversions)
- ROAS
- CPC

Filter: Date >= 30 days, Clicks >= 10
Sorting: ROAS DESC
Limit: Top 25
```

#### 2. Pause Candidates (Table)
```
Dimensions:
- Keyword Text
- Campaign Name

Metrics:
- SUM(clicks)
- SUM(cost) / 1000000
- SUM(conversions)

Filter: 
- Date >= 30 days
- Conversions = 0
- Clicks >= 20

Sorting: Spend DESC
Shows keywords wasting money
```

#### 3. Bid Opportunity Matrix (Scatter Chart)
```
X-Axis: SUM(clicks)
Y-Axis: ROAS
Size: SUM(cost)
Color: Campaign Name

Shows:
- High spend, high ROAS (maintain)
- High spend, low ROAS (reduce)
- Low spend, high ROAS (increase)
```

#### 4. Keywords Performance Scorecard
```
Cards showing:
1. Number of keywords
2. Keywords with 0 conversions
3. Best CPA keyword
4. Best ROAS keyword
```

---

## 📊 Dashboard 4: ROI & Profitability

### Purpose
Monitor overall profitability and ROI.

### Components

#### 1. Key Metrics Summary
```
Scorecards:
1. Total Revenue (SUM(conversion_value))
2. Total Spend (SUM(cost) / 1000000)
3. Blended ROAS (revenue / spend)
4. Net Profit (revenue - spend)
5. ROI % ((revenue - spend) / spend * 100)
6. Avg CPA (spend / conversions)
```

#### 2. Revenue vs. Spend (Area Chart)
```
Dimension: Date
Metrics:
- SUM(conversion_value) as Revenue
- SUM(cost) / 1000000 as Spend

Shows profit margin over time
```

#### 3. ROAS by Campaign (Bar Chart)
```
Dimension: Campaign Name
Metric: ROAS

Reference line: Target ROAS (3.5x)
Color coding:
- Green if > target
- Red if < target
```

#### 4. Campaign Profitability Table
```
Dimensions:
- Campaign Name
- Month

Metrics:
- Revenue
- Spend
- Net Profit
- ROI %
- ROAS

Sorting: Profit DESC
```

#### 5. Conversion Funnel (Funnel Chart)
```
Stages:
1. Impressions
2. Clicks
3. Conversions
4. High-value Conversions (>$50)

Shows: How many users move through each stage
```

---

## 🎨 Design Best Practices

### Color Scheme
```
Success (Green):      #34A853
Warning (Yellow):     #FBBC04
Danger (Red):         #EA4335
Neutral (Blue):       #4285F4
Text (Dark):          #202124
Background (Light):   #F8F9FA
```

### Layout Tips

1. **Top Row: KPIs**
   - Scorecards for key metrics
   - 4-6 cards showing today's performance

2. **Middle Row: Trends**
   - Line charts showing 30-day trends
   - ROAS and CPA trends by campaign

3. **Bottom Row: Details**
   - Data tables for drill-down
   - Detailed keyword/campaign data

### Interactive Features

1. **Date Range Selector**
   - Add at top: Last 7/30/90 days
   - Allow custom date selection

2. **Campaign Filter**
   - Dropdown to filter by campaign
   - Shows "All Campaigns" by default

3. **Drill-Down Tables**
   - Click campaign → see keywords
   - Click keyword → see ad groups

---

## 📱 Creating Each Dashboard

### Step 1: Layout Dashboard
- Insert grid/layout guides
- Arrange components in sections
- Set consistent spacing (12px grid)

### Step 2: Add Visualizations
```
Click "Insert" → Select Chart Type

Common types:
- Scorecard (for KPIs)
- Table (for data drill-down)
- Line Chart (for trends)
- Bar Chart (for comparisons)
- Pie Chart (for composition)
- Heatmap (for patterns)
```

### Step 3: Configure Data
```
1. Click chart
2. Click "Data" tab
3. Select dimensions & metrics
4. Set filters
5. Configure sorting
```

### Step 4: Style Components
```
1. Click chart
2. Click "Style" tab
3. Set colors, fonts, borders
4. Add title & subtitle
5. Format numbers (currency, %)
```

---

## 🔄 Sharing & Collaboration

### Share Dashboard
1. Click **"Share"** (top right)
2. Choose access level:
   - Viewer (read-only)
   - Editor (can modify)
3. Add email addresses
4. Send invite

### Set Up Automated Reports
1. Click **"File"** → **"Email & schedule"**
2. Choose:
   - Recipients
   - Frequency (daily/weekly)
   - Time to send
3. Enable notifications

### Create Filters for Viewers
1. Add filter to dashboard
2. Set "Apply to all charts"
3. Viewers can change filter dynamically

---

## 📊 Sample Queries for Dashboards

### For Looker Studio Calculations

**ROAS Formula:**
```
SUM(conversion_value) / (SUM(cost_micros) / 1000000)
```

**CPA Formula:**
```
(SUM(cost_micros) / 1000000) / SUM(conversions)
```

**CPC Formula:**
```
(SUM(cost_micros) / 1000000) / SUM(clicks)
```

**CTR Formula:**
```
SUM(clicks) / SUM(impressions) * 100
```

**Conversion Rate Formula:**
```
SUM(conversions) / SUM(clicks) * 100
```

---

## 🚨 Common Issues & Fixes

### Data Not Showing
- Check BigQuery data freshness
- Verify dataset has recent data
- Check date filters

### Charts Look Blank
- Verify metric aggregation
- Check if metric has data for date range
- Look at chart configuration

### Performance Slow
- Reduce date range
- Use pre-aggregated tables
- Add filters to reduce data

### Numbers Look Wrong
- Check metric calculations
- Verify currency conversions
- Look at filter conditions

---

## 📈 Advanced Features

### Custom Alerts
```
Set up email alerts when:
- ROAS drops below 2.0x
- CPA exceeds budget
- Daily spend exceeds threshold
```

### Data Blending
```
Combine BigQuery data with:
- Google Sheets (for manual data)
- YouTube Analytics
- GA4 data
```

### Custom Metrics
```
Create calculated fields:
- Blended ROAS
- Efficiency Index
- Cost Per Lead
```

---

## 📚 Resources

- **Looker Studio Help:** https://support.google.com/datastudio
- **BigQuery SQL Reference:** https://cloud.google.com/bigquery/docs/reference/standard-sql
- **Dashboard Templates:** https://lookerstudio.google.com/gallery

---

## ✅ Dashboard Checklist

- [ ] Created 4 main dashboards
- [ ] Connected BigQuery data source
- [ ] Added date range filters
- [ ] Configured all metrics
- [ ] Applied consistent styling
- [ ] Added interactivity (filters, drill-down)
- [ ] Set up data refresh schedule
- [ ] Shared with team
- [ ] Tested on mobile devices
- [ ] Set up automated reports

---

**Dashboard Creation Tips:**
- Start simple, add complexity gradually
- Use consistent color schemes
- Add context (targets, benchmarks)
- Make it mobile-friendly
- Update regularly (weekly reviews)

---

**For Help:** Check Google's dashboard templates gallery or reach out to your analytics team!
