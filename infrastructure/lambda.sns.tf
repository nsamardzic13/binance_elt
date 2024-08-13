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
  alarm_name          = "${var.project_name}-lambda-error-count-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "${var.project_name}-Lambda/Errors"
  period              = 1200 # 20 min
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "${aws_lambda_function.lambda_function.function_name} failed"
  alarm_actions       = [aws_sns_topic.tf_binance_lambda.arn]

  dimensions = {
    FunctionName = aws_lambda_function.lambda_function.function_name
  }
}


resource "aws_cloudwatch_metric_alarm" "ecs_task_failure" {
  alarm_name          = "${var.project_name}-ecs-task-failure-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EcsTaskFailures"
  namespace           = "${var.project_name}-ECS/TaskFailure"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "${aws_ecs_cluster.ecs.name} failed"
  alarm_actions       = [aws_sns_topic.tf_binance_lambda.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs.name
  }
}