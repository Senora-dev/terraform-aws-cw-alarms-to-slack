# CloudWatch to Slack Alerts Terraform Module

This Terraform module sets up CloudWatch alarms that send notifications to Slack through a Lambda function.

## Features

- Creates CloudWatch alarms from JSON configuration
- Sets up SNS topic for alarm notifications
- Creates Lambda function to forward alerts to Slack
- Configures necessary IAM roles and permissions
- Supports multiple environments
- Includes proper tagging

## Prerequisites

- AWS account with appropriate permissions
- Terraform >= 0.13
- Slack webhook URL
- Python 3.9 runtime support in AWS Lambda

## Usage

1. Create your `alarms.json` file with your desired alarms configuration:

```json
[
  {
    "name": "HighCPU",
    "metric": "CPUUtilization",
    "threshold": 80,
    "comparison_operator": "GreaterThanThreshold",
    "period": 300,
    "evaluation_periods": 1,
    "namespace": "AWS/EC2",
    "statistic": "Average",
    "dimensions": {
      "InstanceId": "i-0123456789abcdef0"
    }
  }
]
```

2. Create a Terraform configuration file:

```hcl
module "cloudwatch_alerts" {
  source = "path/to/module"

  environment      = "prod"
  slack_webhook_url = "https://hooks.slack.com/services/XXX/YYY/ZZZ"
  
  tags = {
    Project     = "MyProject"
    Environment = "Production"
  }
}
```

## Variables

| Name | Description | Type | Required |
|------|-------------|------|----------|
| environment | Environment name (e.g., dev, staging, prod) | string | yes |
| slack_webhook_url | Slack webhook URL for sending notifications | string | yes |
| tags | A map of tags to add to all resources | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| sns_topic_arn | ARN of the SNS topic |
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_name | Name of the Lambda function |
| cloudwatch_alarms | Map of CloudWatch alarms created |

## Alarm Configuration

The `alarms.json` file supports the following fields for each alarm:

- `name`: Alarm name
- `metric`: CloudWatch metric name
- `threshold`: Threshold value
- `comparison_operator`: Comparison operator
- `period`: Period in seconds
- `evaluation_periods`: Number of periods to evaluate
- `namespace`: CloudWatch namespace
- `statistic`: Statistic type
- `dimensions`: Metric dimensions

## Slack Notifications

The Lambda function sends formatted messages to Slack with:

- Alarm name and status
- Region information
- Detailed reason for the alarm
- Color-coded status (red for ALARM, green for OK)
- Timestamp of the event

## Installation

1. Copy this module to your Terraform project
2. Configure your `alarms.json`
3. Create your Terraform configuration
4. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Testing

To test the setup:

1. Deploy the module
2. Manually trigger a test alarm
3. Verify the notification appears in your Slack channel

## Notes

- Ensure your AWS credentials have the necessary permissions
- The Lambda function uses Python 3.9 runtime
- All resources are tagged with environment and name
- SNS topic and Lambda function names include the environment prefix

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This module is released under the MIT License. 