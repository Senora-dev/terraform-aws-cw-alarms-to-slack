output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.cloudwatch_to_slack.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.slack_notifier.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.slack_notifier.function_name
}

output "cloudwatch_alarms" {
  description = "Map of CloudWatch alarms created"
  value       = { for k, v in aws_cloudwatch_metric_alarm.alarms : k => v.arn }
} 