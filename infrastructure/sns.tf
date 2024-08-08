# log group metric + alarm
resource "aws_cloudwatch_log_metric_filter" "lambda_log_errors_count_metric" {
  name           = "${var.project_name}-log-metric-filter"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.lambda_log_group.name

  metric_transformation {
    name      = "${var.project_name}-error-count"
    namespace = "${var.project_name}-lambda-errors"
    value     = "1"
  }
}

resource "aws_sns_topic" "tf_binance_lambda" {
  name = "${var.project_name}-sns-lambda"
}

resource "aws_sns_topic_subscription" "tf_user_updates_sqs_target" {
  topic_arn = aws_sns_topic.tf_binance_lambda.arn
  protocol  = "email"
  endpoint  = var.sns_email_address
}
resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.tf_binance_lambda.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }

    resources = [aws_sns_topic.tf_binance_lambda.arn]
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_count_alarm" {
  alarm_name                = "${var.project_name}-error-count-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = aws_cloudwatch_log_metric_filter.lambda_log_errors_count_metric.name
  namespace                 = "${var.project_name}-lambda-errors"
  period                    = 1500 # 25 min
  statistic                 = "SampleCount"
  alarm_description         = "${aws_lambda_function.lambda_function.function_name} failed"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.tf_binance_lambda.arn]
}