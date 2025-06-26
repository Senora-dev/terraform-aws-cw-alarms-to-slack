provider "aws" {
  region = "us-east-1"
}

module "cw_alarms_to_slack" {
  source              = "../.."
  environment         = "dev"
  alarms_config_path  = "${path.module}/alarms.json"
  slack_webhook_urls  = {
    default = "https://hooks.slack.com/services/XXX/YYY/ZZZ"
  }

  tags = {
    Project     = "ExampleProject"
    Environment = "dev"
  }
} 