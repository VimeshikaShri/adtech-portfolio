#!/usr/bin/env python3
"""
Budget Monitor Script for Google Ads - DEMO VERSION
Uses mock data to demonstrate functionality
Perfect for portfolio projects when API access is limited
"""

import argparse
import logging
import yaml
from datetime import datetime
import random

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class BudgetMonitor:
    """Monitor Google Ads budget and spending"""
    
    def __init__(self, config_file):
        """Initialize budget monitor with config file"""
        logger.info("Running budget monitor (DEMO MODE with sample data)")
        
        # Load config
        with open(config_file, 'r') as f:
            self.config = yaml.safe_load(f)
        
        self.customer_id = self.config['google_ads']['customer_id']
        
    def get_budget_data(self):
        """Generate realistic sample budget data"""
        try:
            # Generate realistic sample data
            campaigns_data = [
                {
                    'id': '1001',
                    'name': 'Summer Sale Campaign',
                    'impressions': random.randint(5000, 15000),
                    'clicks': random.randint(200, 800),
                    'cost': random.uniform(500, 2000),
                    'conversions': random.randint(20, 100),
                    'conversion_value': random.uniform(1000, 5000)
                },
                {
                    'id': '1002',
                    'name': 'Brand Awareness Campaign',
                    'impressions': random.randint(10000, 30000),
                    'clicks': random.randint(300, 1000),
                    'cost': random.uniform(1000, 3000),
                    'conversions': random.randint(30, 120),
                    'conversion_value': random.uniform(2000, 8000)
                },
                {
                    'id': '1003',
                    'name': 'Product Launch Campaign',
                    'impressions': random.randint(3000, 10000),
                    'clicks': random.randint(150, 500),
                    'cost': random.uniform(800, 1500),
                    'conversions': random.randint(15, 60),
                    'conversion_value': random.uniform(800, 3000)
                },
                {
                    'id': '1004',
                    'name': 'Retargeting Campaign',
                    'impressions': random.randint(8000, 20000),
                    'clicks': random.randint(250, 700),
                    'cost': random.uniform(600, 1800),
                    'conversions': random.randint(25, 90),
                    'conversion_value': random.uniform(1200, 4500)
                }
            ]
            
            # Calculate total cost
            total_cost = sum(c['cost'] for c in campaigns_data)
            
            return {
                'campaigns': campaigns_data,
                'total_cost': total_cost,
                'timestamp': datetime.now(),
                'is_demo': True
            }
            
        except Exception as ex:
            logger.error(f"Error generating sample data: {ex}")
            return None
    
    def display_report(self, data):
        """Display budget report"""
        if not data:
            logger.error("Error retrieving budget data")
            return
        
        total_cost = data['total_cost']
        daily_budget = self.config['bidding_strategy']['daily_budget_usd']
        pace = (total_cost / daily_budget * 100) if daily_budget > 0 else 0
        
        # Calculate metrics
        total_conversions = sum(c['conversions'] for c in data['campaigns'])
        total_conversion_value = sum(c['conversion_value'] for c in data['campaigns'])
        total_clicks = sum(c['clicks'] for c in data['campaigns'])
        
        # Calculate ROAS and CPA
        roas = (total_conversion_value / total_cost) if total_cost > 0 else 0
        cpa = (total_cost / total_conversions) if total_conversions > 0 else 0
        ctr = (total_clicks / sum(c['impressions'] for c in data['campaigns']) * 100) if sum(c['impressions'] for c in data['campaigns']) > 0 else 0
        
        # Determine status
        if pace > 110:
            status = "🔴 OVERSPEND"
        elif pace > 90:
            status = "🟡 WARNING"
        else:
            status = "🟩 ON_TRACK"
        
        # ROAS status
        roas_target = self.config['bidding_strategy']['roas_target']
        if roas >= roas_target:
            roas_status = "✅ EXCEEDING"
        elif roas >= roas_target * 0.8:
            roas_status = "🟡 NEAR TARGET"
        else:
            roas_status = "⚠️ BELOW TARGET"
        
        # CPA status
        cpa_target = self.config['bidding_strategy']['cpa_target']
        if cpa <= cpa_target:
            cpa_status = "✅ GOOD"
        elif cpa <= cpa_target * 1.2:
            cpa_status = "🟡 ACCEPTABLE"
        else:
            cpa_status = "❌ HIGH"
        
        print("\n" + "="*70)
        print(f"📊 Daily Budget Report - {data['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}")
        print("="*70)
        
        if data.get('is_demo'):
            print("📌 [DEMO MODE] Using sample data for portfolio demonstration\n")
        
        print("BUDGET METRICS:")
        print("-" * 70)
        print(f"Total Spend:       ${total_cost:>10.2f} / ${daily_budget:>10.2f}")
        print(f"Budget Pace:       {pace:>10.1f}%")
        print(f"Status:            {status:>20}")
        
        print("\nPERFORMANCE METRICS:")
        print("-" * 70)
        print(f"Total Impressions: {sum(c['impressions'] for c in data['campaigns']):>10,}")
        print(f"Total Clicks:      {total_clicks:>10,}")
        print(f"Click-Through Rate:{ctr:>10.2f}%")
        print(f"Total Conversions: {total_conversions:>10,}")
        print(f"Revenue Generated: ${total_conversion_value:>10.2f}")
        
        print("\nKEY METRICS:")
        print("-" * 70)
        print(f"ROAS (Target: {roas_target}x):      {roas:>10.2f}x  {roas_status:>20}")
        print(f"CPA (Target: ${cpa_target:.2f}):     ${cpa:>10.2f}  {cpa_status:>20}")
        
        print("\nCOMPAIGN BREAKDOWN (Top 5 by Spend):")
        print("-" * 70)
        sorted_campaigns = sorted(
            data['campaigns'],
            key=lambda x: x['cost'],
            reverse=True
        )[:5]
        
        for i, campaign in enumerate(sorted_campaigns, 1):
            campaign_roas = (campaign['conversion_value'] / campaign['cost']) if campaign['cost'] > 0 else 0
            print(f"{i}. {campaign['name'][:40]:40} | ${campaign['cost']:>8.2f} | {campaign['clicks']:>4} clicks | ROAS: {campaign_roas:.2f}x")
        
        print("\n" + "="*70)
        print("✅ Report generated successfully!")
        print("="*70 + "\n")


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Monitor Google Ads budget (DEMO MODE)')
    parser.add_argument('--config', default='config.yaml', help='Config file path')
    parser.add_argument('--once', action='store_true', help='Run once and exit')
    
    args = parser.parse_args()
    
    try:
        monitor = BudgetMonitor(args.config)
        data = monitor.get_budget_data()
        monitor.display_report(data)
        
        if not args.once:
            logger.info("Budget monitor running. Press Ctrl+C to stop.")
            
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        raise


if __name__ == "__main__":
    main()
