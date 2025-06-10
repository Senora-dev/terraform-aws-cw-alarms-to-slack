import json
import urllib3
import os
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

http = urllib3.PoolManager()

def get_webhook_url(channel):
    """
    Get the webhook URL for a specific channel from environment variables
    The format is SLACK_WEBHOOK_URL_<channel> (converted to uppercase)
    """
    env_var = f"SLACK_WEBHOOK_URL_{channel.upper().replace('-', '_')}"
    webhook_url = os.environ.get(env_var)
    if not webhook_url:
        # Fallback to default webhook if channel-specific one is not found
        webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
        logger.warning(f"No webhook URL found for channel {channel}, using default webhook")
    return webhook_url

def lambda_handler(event, context):
    """
    Lambda function to forward CloudWatch alarms to Slack
    """
    try:
        logger.info("Processing SNS event: %s", event)
        
        # Parse the SNS message
        sns_message = event['Records'][0]['Sns']['Message']
        alarm_data = json.loads(sns_message)
        
        # Get alarm tags to find the Slack channel
        alarm_name = alarm_data['AlarmName']
        environment = alarm_name.split('-')[0]  # Extract environment from alarm name
        
        # Get alarm configuration from alarm description (which contains our JSON config)
        alarm_config = json.loads(alarm_data.get('AlarmDescription', '{}'))
        slack_channel = alarm_config.get('slack_channel', 'general')
        
        # Get webhook URL for this channel
        slack_webhook_url = get_webhook_url(slack_channel)
        if not slack_webhook_url:
            raise ValueError(f"No webhook URL found for channel {slack_channel}")
        
        # Create Slack message
        color = "#FF0000" if alarm_data['NewStateValue'] == 'ALARM' else "#36A64F"
        
        slack_message = {
            "channel": f"#{slack_channel}",
            "attachments": [
                {
                    "color": color,
                    "title": f"CloudWatch Alarm: {alarm_data['AlarmName']}",
                    "fields": [
                        {
                            "title": "Status",
                            "value": alarm_data['NewStateValue'],
                            "short": True
                        },
                        {
                            "title": "Region",
                            "value": alarm_data['Region'],
                            "short": True
                        },
                        {
                            "title": "Environment",
                            "value": environment,
                            "short": True
                        },
                        {
                            "title": "Channel",
                            "value": slack_channel,
                            "short": True
                        },
                        {
                            "title": "Reason",
                            "value": alarm_data['NewStateReason'],
                            "short": False
                        }
                    ],
                    "footer": "AWS CloudWatch Alarm",
                    "ts": int(alarm_data['StateChangeTime'].timestamp())
                }
            ]
        }
        
        # Send to Slack
        encoded_msg = json.dumps(slack_message).encode('utf-8')
        resp = http.request('POST', slack_webhook_url,
                          body=encoded_msg,
                          headers={'Content-Type': 'application/json'})
        
        logger.info("Message sent to Slack channel %s - Status: %d", slack_channel, resp.status)
        
        return {
            'statusCode': 200,
            'body': json.dumps('Successfully sent alarm to Slack')
        }
        
    except Exception as e:
        logger.error("Error processing alarm: %s", str(e))
        raise 
