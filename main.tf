#--- Locals ---#
locals {
  alarms = jsondecode(file(var.alarms_config_path))
  
  # Create map of alarms by name
  alarms_by_name = {
    for alarm in local.alarms : alarm.name => alarm
  }
}

#--- CloudWatch Alarms ---#
resource "aws_cloudwatch_metric_alarm" "alarms" {
  for_each = local.alarms_by_name

  alarm_name          = "${var.environment}-${each.value.name}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric
  namespace           = each.value.namespace
  period             = each.value.period
  threshold          = each.value.threshold
  dimensions         = each.value.dimensions
  statistic          = each.value.statistic
  alarm_description  = jsonencode(merge(each.value, { environment = var.environment }))
  alarm_actions      = [aws_sns_topic.cloudwatch_to_slack.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_to_slack.arn]

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.environment}-${each.value.name}"
    }
  )
}

#--- SNS ---#
resource "aws_sns_topic" "cloudwatch_to_slack" {
  name = "${var.environment}-cloudwatch-to-slack"

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.environment}-cloudwatch-to-slack"
    }
  )
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.cloudwatch_to_slack.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cloudwatch_to_slack.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount": data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_to_slack.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

#--- IAM ---#
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.environment}-lambda-cloudwatch-to-slack"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.environment}-lambda-cloudwatch-to-slack"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sns" {
  name = "${var.environment}-lambda-sns-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe",
          "sns:Unsubscribe"
        ]
        Resource = [aws_sns_topic.cloudwatch_to_slack.arn]
      }
    ]
  })
}

#--- Lambda ---#
resource "aws_lambda_function" "slack_notifier" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-cloudwatch-slack-notifier"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 128

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SLACK_WEBHOOK_URLS = jsonencode(var.slack_webhook_urls)
    }
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.environment}-cloudwatch-slack-notifier"
    }
  )
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_to_slack.arn
}