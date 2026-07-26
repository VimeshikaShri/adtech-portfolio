#!/usr/bin/env python3
"""
Utility functions for AdTech portfolio
"""

import logging
from typing import Dict, List, Optional
from datetime import datetime, timedelta
import json

logger = logging.getLogger(__name__)


class MetricsCalculator:
    """Calculate common marketing metrics"""
    
    @staticmethod
    def calculate_roas(revenue: float, spend: float) -> float:
        """Calculate Return on Ad Spend"""
        return revenue / spend if spend > 0 else 0
    
    @staticmethod
    def calculate_cpa(spend: float, conversions: int) -> float:
        """Calculate Cost Per Acquisition"""
        return spend / conversions if conversions > 0 else float('inf')
    
    @staticmethod
    def calculate_cpc(spend: float, clicks: int) -> float:
        """Calculate Cost Per Click"""
        return spend / clicks if clicks > 0 else 0
    
    @staticmethod
    def calculate_ctr(clicks: int, impressions: int) -> float:
        """Calculate Click-Through Rate (as percentage)"""
        return (clicks / impressions * 100) if impressions > 0 else 0
    
    @staticmethod
    def calculate_conversion_rate(conversions: int, clicks: int) -> float:
        """Calculate Conversion Rate (as percentage)"""
        return (conversions / clicks * 100) if clicks > 0 else 0
    
    @staticmethod
    def calculate_ltv(revenue: float, unique_users: int) -> float:
        """Calculate Lifetime Value per user"""
        return revenue / unique_users if unique_users > 0 else 0


class BudgetForecaster:
    """Forecast budget and spending"""
    
    @staticmethod
    def project_monthly_spend(daily_spend: float, current_day: int, days_in_month: int = 30) -> float:
        """Project total monthly spend based on current pace"""
        days_remaining = days_in_month - current_day
        return daily_spend * days_in_month
    
    @staticmethod
    def calculate_remaining_budget(total_budget: float, spent: float) -> float:
        """Calculate remaining budget"""
        return max(0, total_budget - spent)
    
    @staticmethod
    def get_pace_percentage(spent: float, daily_budget: float, current_day: int) -> float:
        """Calculate budget pace as percentage"""
        expected_spend = daily_budget * current_day
        return (spent / expected_spend * 100) if expected_spend > 0 else 0
    
    @staticmethod
    def should_adjust_budget(pace: float, threshold_high: float = 110, threshold_low: float = 50) -> Optional[str]:
        """Determine if budget adjustment is needed"""
        if pace > threshold_high:
            return 'REDUCE'
        elif pace < threshold_low:
            return 'INCREASE'
        return None


class BidOptimizer:
    """Bid optimization recommendations"""
    
    @staticmethod
    def recommend_bid_adjustment(
        current_roas: float,
        target_roas: float,
        current_bid: float,
        min_bid: float,
        max_bid: float
    ) -> Dict:
        """Recommend bid adjustment based on ROAS"""
        
        adjustment_factor = target_roas / current_roas if current_roas > 0 else 0.8
        
        # Cap adjustment to ±20% per day
        adjustment_factor = max(0.8, min(1.2, adjustment_factor))
        
        new_bid = current_bid * adjustment_factor
        new_bid = max(min_bid, min(max_bid, new_bid))
        
        return {
            'current_bid': current_bid,
            'recommended_bid': new_bid,
            'adjustment_percent': (adjustment_factor - 1) * 100,
            'rationale': BidOptimizer._get_rationale(current_roas, target_roas)
        }
    
    @staticmethod
    def _get_rationale(current: float, target: float) -> str:
        """Get rationale for bid recommendation"""
        if current > target:
            return f"ROAS {current:.2f}x exceeds target {target:.2f}x - increase bid to capture more volume"
        elif current < target * 0.5:
            return f"ROAS {current:.2f}x critically below target - reduce bid aggressively"
        else:
            return f"ROAS {current:.2f}x below target - reduce bid to improve efficiency"


class ReportGenerator:
    """Generate reports for marketing campaigns"""
    
    @staticmethod
    def generate_daily_report(
        date: datetime,
        campaigns: List[Dict],
        metrics_summary: Dict
    ) -> str:
        """Generate daily performance report"""
        
        report = f"📈 Daily Performance Report - {date.strftime('%Y-%m-%d')}\n"
        report += "=" * 70 + "\n\n"
        
        # Summary metrics
        report += "Summary Metrics:\n"
        report += f"  Impressions: {metrics_summary.get('impressions', 0):,}\n"
        report += f"  Clicks: {metrics_summary.get('clicks', 0):,}\n"
        report += f"  Conversions: {metrics_summary.get('conversions', 0):,}\n"
        report += f"  Spend: ${metrics_summary.get('spend', 0):.2f}\n"
        report += f"  Revenue: ${metrics_summary.get('revenue', 0):.2f}\n"
        report += f"  ROAS: {metrics_summary.get('roas', 0):.2f}x\n"
        report += f"  CPA: ${metrics_summary.get('cpa', 0):.2f}\n\n"
        
        # Campaign breakdown
        report += "Top Campaigns:\n"
        report += "-" * 70 + "\n"
        
        for campaign in sorted(campaigns, key=lambda x: x.get('revenue', 0), reverse=True)[:10]:
            report += f"{campaign['name']}\n"
            report += f"  ROAS: {campaign.get('roas', 0):.2f}x | "
            report += f"Spend: ${campaign.get('spend', 0):.2f} | "
            report += f"Revenue: ${campaign.get('revenue', 0):.2f}\n"
        
        return report
    
    @staticmethod
    def generate_weekly_summary(week_data: List[Dict]) -> str:
        """Generate weekly summary report"""
        
        total_spend = sum(day['spend'] for day in week_data)
        total_revenue = sum(day['revenue'] for day in week_data)
        total_conversions = sum(day['conversions'] for day in week_data)
        
        report = "📊 Weekly Summary Report\n"
        report += "=" * 70 + "\n\n"
        
        report += f"Total Spend: ${total_spend:.2f}\n"
        report += f"Total Revenue: ${total_revenue:.2f}\n"
        report += f"Weekly ROAS: {total_revenue / total_spend if total_spend > 0 else 0:.2f}x\n"
        report += f"Total Conversions: {total_conversions}\n"
        
        return report


class SlackFormatter:
    """Format messages for Slack"""
    
    @staticmethod
    def format_alert(
        title: str,
        metrics: Dict,
        color: str = 'warning'
    ) -> Dict:
        """Format alert message for Slack"""
        
        color_map = {
            'success': '#36a64f',
            'warning': '#ff9900',
            'danger': '#ff0000'
        }
        
        attachments = [{
            'color': color_map.get(color, color),
            'title': title,
            'text': '\n'.join([
                f"*{key}*: {value}" for key, value in metrics.items()
            ]),
            'ts': int(datetime.now().timestamp())
        }]
        
        return {'attachments': attachments}


class DataValidator:
    """Validate marketing data"""
    
    @staticmethod
    def validate_metrics(metrics: Dict) -> bool:
        """Validate metric dictionary"""
        required_keys = ['spend', 'revenue', 'conversions']
        
        for key in required_keys:
            if key not in metrics:
                logger.warning(f"Missing required metric: {key}")
                return False
            
            if not isinstance(metrics[key], (int, float)):
                logger.warning(f"Invalid type for metric {key}")
                return False
        
        return True
    
    @staticmethod
    def validate_campaign_data(campaign: Dict) -> bool:
        """Validate campaign data"""
        required_fields = ['campaign_id', 'campaign_name']
        
        return all(field in campaign for field in required_fields)


class ConfigValidator:
    """Validate configuration files"""
    
    @staticmethod
    def validate_config(config: Dict) -> bool:
        """Validate configuration dictionary"""
        required_sections = [
            'google_ads',
            'bidding_strategy',
            'budget_monitor'
        ]
        
        for section in required_sections:
            if section not in config:
                logger.error(f"Missing required config section: {section}")
                return False
        
        # Validate Google Ads config
        ga_config = config['google_ads']
        ga_required = ['customer_id', 'developer_token']
        
        for key in ga_required:
            if key not in ga_config:
                logger.error(f"Missing required Google Ads config: {key}")
                return False
        
        return True


def setup_logging(log_file: str = 'logs/adtech.log', level: str = 'INFO'):
    """Setup logging configuration"""
    import os
    
    # Create logs directory if it doesn't exist
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    
    logging.basicConfig(
        level=getattr(logging, level),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
