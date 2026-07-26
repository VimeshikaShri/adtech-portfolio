#!/usr/bin/env python3
"""
Automated Bidding Strategy for Google Ads
Optimizes keyword bids based on ROAS targets, CPA goals, and performance metrics.
"""

import json
import logging
import sys
from typing import Dict, List, Tuple, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass
import yaml
from google.ads.googleads.client import GoogleAdsClient
from google.ads.googleads.v14.services.google_ads_service import GoogleAdsServiceClient
from google.ads.googleads.v14.types import AdGroupCriterion
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/bidding_strategy.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


@dataclass
class KeywordMetrics:
    """Container for keyword performance metrics"""
    keyword_id: str
    keyword_text: str
    current_bid_micros: int
    impressions: int
    clicks: int
    conversions: int
    cost_micros: int
    revenue: float
    
    @property
    def cpc(self) -> float:
        """Calculate cost per click"""
        return (self.cost_micros / 1e6) / self.clicks if self.clicks > 0 else 0
    
    @property
    def cpa(self) -> float:
        """Calculate cost per acquisition"""
        return (self.cost_micros / 1e6) / self.conversions if self.conversions > 0 else float('inf')
    
    @property
    def roas(self) -> float:
        """Calculate return on ad spend"""
        cost_usd = self.cost_micros / 1e6
        return self.revenue / cost_usd if cost_usd > 0 else 0
    
    @property
    def ctr(self) -> float:
        """Calculate click-through rate"""
        return (self.clicks / self.impressions * 100) if self.impressions > 0 else 0


class AutomatedBiddingStrategy:
    """Main class for automated bid optimization"""
    
    def __init__(self, config_path: str, dry_run: bool = False):
        """Initialize bidding strategy with config"""
        self.dry_run = dry_run
        self.config = self._load_config(config_path)
        self.client = GoogleAdsClient.load_from_storage('google-ads.yaml')
        self.customer_id = self.config['google_ads']['customer_id']
        self.logger = logger
        
        # Strategy parameters
        self.roas_target = self.config['bidding_strategy']['roas_target']
        self.cpa_target = self.config['bidding_strategy']['cpa_target']
        self.min_bid_micros = self.config['bidding_strategy']['min_bid_micros']
        self.max_bid_micros = self.config['bidding_strategy']['max_bid_micros']
        self.daily_adjustment_percent = self.config['bidding_strategy']['daily_bid_adjustment_percent']
        self.pause_below_roas = self.config['bidding_strategy']['pause_below_roas']
        
        self.logger.info(f"Initialized bidding strategy with ROAS target: {self.roas_target}x")
    
    @staticmethod
    def _load_config(config_path: str) -> Dict:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            print(f"Config file not found: {config_path}")
            sys.exit(1)
    
    def get_campaign_keywords(self, campaign_id: str) -> List[KeywordMetrics]:
        """Fetch all keywords for a campaign with performance metrics"""
        ga_service = self.client.get_service("GoogleAdsService")
        
        query = f"""
            SELECT 
                ad_group_criterion.criterion_id,
                ad_group_criterion.keyword.text,
                ad_group_criterion.cpc_bid_micros,
                metrics.impressions,
                metrics.clicks,
                metrics.conversions_from_interactions,
                metrics.cost_micros,
                metrics.conversion_value
            FROM ad_group_criterion
            WHERE campaign.id = '{campaign_id}'
                AND ad_group_criterion.type = 'KEYWORD'
                AND ad_group_criterion.status = 'ENABLED'
                AND metrics.impressions > 50
            ORDER BY metrics.cost_micros DESC
        """
        
        try:
            results = ga_service.search_stream(customer_id=self.customer_id, query=query)
            keywords = []
            
            for batch in results:
                for row in batch.results:
                    keyword = KeywordMetrics(
                        keyword_id=str(row.ad_group_criterion.criterion_id),
                        keyword_text=row.ad_group_criterion.keyword.text,
                        current_bid_micros=row.ad_group_criterion.cpc_bid_micros,
                        impressions=row.metrics.impressions,
                        clicks=row.metrics.clicks,
                        conversions=row.metrics.conversions_from_interactions,
                        cost_micros=row.metrics.cost_micros,
                        revenue=row.metrics.conversion_value
                    )
                    keywords.append(keyword)
            
            self.logger.info(f"Fetched {len(keywords)} keywords for campaign {campaign_id}")
            return keywords
        
        except Exception as e:
            self.logger.error(f"Error fetching keywords: {e}")
            return []
    
    def calculate_new_bid(self, keyword: KeywordMetrics) -> int:
        """Calculate recommended bid based on performance"""
        current_bid = keyword.current_bid_micros
        
        # If no conversions, reduce bid aggressively
        if keyword.conversions == 0:
            new_bid = int(current_bid * 0.7)
            return max(self.min_bid_micros, new_bid)
        
        # ROAS-based optimization
        roas = keyword.roas
        if roas > 0:
            # If performing above ROAS target, increase bid
            if roas > self.roas_target:
                adjustment_factor = 1.0 + (self.daily_adjustment_percent / 100)
            # If performing below ROAS target, decrease bid
            elif roas < self.pause_below_roas:
                adjustment_factor = 0.5  # Aggressive reduction
            else:
                adjustment_factor = 0.9  # Slight reduction
            
            new_bid = int(current_bid * adjustment_factor)
        
        # CPA-based optimization
        elif keyword.cpa < self.cpa_target:
            # Lower CPA = good performer, increase bid
            adjustment_factor = 1.0 + (self.daily_adjustment_percent / 100)
            new_bid = int(current_bid * adjustment_factor)
        
        elif keyword.cpa > self.cpa_target * 1.5:
            # Higher CPA = poor performer, decrease bid
            adjustment_factor = 0.8
            new_bid = int(current_bid * adjustment_factor)
        
        else:
            new_bid = current_bid
        
        # Enforce bid limits
        return max(self.min_bid_micros, min(self.max_bid_micros, new_bid))
    
    def should_pause_keyword(self, keyword: KeywordMetrics) -> bool:
        """Determine if keyword should be paused"""
        # Pause if no conversions in 30 days with high spend
        if keyword.conversions == 0 and (keyword.cost_micros / 1e6) > 100:
            return True
        
        # Pause if ROAS is critically low
        if keyword.roas > 0 and keyword.roas < self.pause_below_roas:
            return True
        
        # Pause if CPA is critically high
        if keyword.cpa > (self.cpa_target * 2.5):
            return True
        
        return False
    
    def apply_bid_changes(self, campaign_id: str, keywords: List[KeywordMetrics]) -> Tuple[int, int]:
        """Apply bid changes to Google Ads"""
        if not keywords:
            return 0, 0
        
        ad_group_criterion_service = self.client.get_service("AdGroupCriterionService")
        bid_changes = 0
        paused_keywords = 0
        
        for keyword in keywords:
            try:
                # Calculate new bid
                new_bid = self.calculate_new_bid(keyword)
                should_pause = self.should_pause_keyword(keyword)
                
                # Log the action
                self._log_bid_action(keyword, new_bid, should_pause)
                
                # Skip if dry run
                if self.dry_run:
                    bid_changes += 1
                    continue
                
                # Prepare the update operation
                criterion_path = ad_group_criterion_service.ad_group_criterion_path(
                    self.customer_id,
                    keyword.keyword_id.split('-')[0],  # ad_group_id
                    keyword.keyword_id
                )
                
                criterion = AdGroupCriterion()
                criterion.resource_name = criterion_path
                criterion.cpc_bid_micros = new_bid
                
                # If pausing, set status
                if should_pause:
                    criterion.status = 2  # PAUSED
                    paused_keywords += 1
                
                # Create mutation operation
                operation = {
                    'update': criterion,
                    'update_mask': {'paths': ['cpc_bid_micros']}
                }
                
                if should_pause:
                    operation['update_mask']['paths'].append('status')
                
                # Apply the change
                response = ad_group_criterion_service.mutate_ad_group_criteria(
                    customer_id=self.customer_id,
                    operations=[operation]
                )
                
                if response.results:
                    bid_changes += 1
                    self.logger.info(f"Updated keyword {keyword.keyword_text}: ${new_bid/1e6:.2f}")
            
            except Exception as e:
                self.logger.error(f"Error updating keyword {keyword.keyword_text}: {e}")
        
        return bid_changes, paused_keywords
    
    def _log_bid_action(self, keyword: KeywordMetrics, new_bid: int, should_pause: bool):
        """Log bid action for audit trail"""
        action = "PAUSE" if should_pause else "UPDATE"
        old_bid = keyword.current_bid_micros / 1e6
        new_bid_usd = new_bid / 1e6
        
        self.logger.info(
            f"{action} | {keyword.keyword_text} | "
            f"Bid: ${old_bid:.2f} → ${new_bid_usd:.2f} | "
            f"ROAS: {keyword.roas:.2f}x | CPA: ${keyword.cpa:.2f}"
        )
    
    def get_campaign_summary(self, campaign_id: str) -> Dict:
        """Get performance summary for a campaign"""
        ga_service = self.client.get_service("GoogleAdsService")
        
        query = f"""
            SELECT 
                campaign.name,
                metrics.impressions,
                metrics.clicks,
                metrics.conversions_from_interactions,
                metrics.cost_micros,
                metrics.conversion_value
            FROM campaign
            WHERE campaign.id = '{campaign_id}'
        """
        
        try:
            results = ga_service.search_stream(customer_id=self.customer_id, query=query)
            
            for batch in results:
                for row in batch.results:
                    metrics = row.metrics
                    cost_usd = metrics.cost_micros / 1e6
                    conversions = metrics.conversions_from_interactions
                    
                    return {
                        'campaign_name': row.campaign.name,
                        'impressions': metrics.impressions,
                        'clicks': metrics.clicks,
                        'conversions': conversions,
                        'cost_usd': cost_usd,
                        'revenue': metrics.conversion_value,
                        'roas': metrics.conversion_value / cost_usd if cost_usd > 0 else 0,
                        'cpa': cost_usd / conversions if conversions > 0 else 0,
                        'cpc': cost_usd / metrics.clicks if metrics.clicks > 0 else 0
                    }
        except Exception as e:
            self.logger.error(f"Error getting campaign summary: {e}")
            return {}
    
    def send_slack_notification(self, message: str):
        """Send notification to Slack"""
        if not self.config.get('slack', {}).get('enabled'):
            return
        
        webhook_url = self.config['slack'].get('webhook_url')
        if not webhook_url:
            return
        
        payload = {
            'text': message,
            'channel': self.config['slack'].get('alert_channel', '#marketing-alerts')
        }
        
        try:
            requests.post(webhook_url, json=payload)
            self.logger.info("Slack notification sent")
        except Exception as e:
            self.logger.error(f"Error sending Slack notification: {e}")
    
    def run_optimization(self, campaign_ids: Optional[List[str]] = None):
        """Run full optimization cycle for specified campaigns"""
        self.logger.info("=" * 80)
        self.logger.info("Starting automated bidding strategy")
        self.logger.info(f"Dry run: {self.dry_run}")
        self.logger.info("=" * 80)
        
        if not campaign_ids:
            # Get all active campaigns
            campaign_ids = self._get_active_campaigns()
        
        total_changes = 0
        total_paused = 0
        
        for campaign_id in campaign_ids:
            self.logger.info(f"\nProcessing campaign {campaign_id}")
            
            # Get campaign summary
            summary = self.get_campaign_summary(campaign_id)
            if summary:
                self.logger.info(
                    f"Campaign: {summary['campaign_name']} | "
                    f"ROAS: {summary['roas']:.2f}x | "
                    f"CPA: ${summary['cpa']:.2f} | "
                    f"Spend: ${summary['cost_usd']:.2f}"
                )
            
            # Get keywords and apply optimizations
            keywords = self.get_campaign_keywords(campaign_id)
            changes, paused = self.apply_bid_changes(campaign_id, keywords)
            
            total_changes += changes
            total_paused += paused
            
            self.logger.info(f"Changes made: {changes} | Keywords paused: {paused}")
        
        # Summary log
        self.logger.info("\n" + "=" * 80)
        self.logger.info(f"Optimization complete")
        self.logger.info(f"Total bid changes: {total_changes}")
        self.logger.info(f"Total keywords paused: {total_paused}")
        self.logger.info("=" * 80)
        
        # Send Slack notification
        message = f":robot_face: Bidding Strategy Update\n" \
                  f"Bid changes: {total_changes}\n" \
                  f"Keywords paused: {total_paused}\n" \
                  f"Mode: {'DRY RUN' if self.dry_run else 'LIVE'}"
        self.send_slack_notification(message)
    
    def _get_active_campaigns(self) -> List[str]:
        """Get all active campaign IDs"""
        ga_service = self.client.get_service("GoogleAdsService")
        
        query = """
            SELECT campaign.id, campaign.name
            FROM campaign
            WHERE campaign.status = 'ENABLED'
            ORDER BY metrics.cost_micros DESC
        """
        
        campaign_ids = []
        try:
            results = ga_service.search_stream(customer_id=self.customer_id, query=query)
            
            for batch in results:
                for row in batch.results:
                    campaign_ids.append(row.campaign.id)
            
            self.logger.info(f"Found {len(campaign_ids)} active campaigns")
            return campaign_ids
        
        except Exception as e:
            self.logger.error(f"Error getting active campaigns: {e}")
            return []


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Automated Bidding Strategy')
    parser.add_argument('--config', default='config.yaml', help='Config file path')
    parser.add_argument('--dry-run', action='store_true', help='Run in dry run mode')
    parser.add_argument('--campaign-id', help='Specific campaign ID to optimize')
    
    args = parser.parse_args()
    
    # Initialize strategy
    strategy = AutomatedBiddingStrategy(args.config, dry_run=args.dry_run)
    
    # Run optimization
    campaign_ids = [args.campaign_id] if args.campaign_id else None
    strategy.run_optimization(campaign_ids)


if __name__ == '__main__':
    main()
