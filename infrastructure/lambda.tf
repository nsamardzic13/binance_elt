data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../lambda"
  output_path = "../lambda.zip"
}

# Define the Lambda function
resource "aws_lambda_function" "lambda_function" {
  function_name = "${var.project_name}-ingest-data"
  description   = "Lambda function to ingest data"
  handler       = "main.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  role          = aws_iam_role.iam_role.arn
  filename      = data.archive_file.lambda.output_path
  memory_size   = 256

  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = var.lambda_layers
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 7
}

# CloudWatch Event rule for every 20 minutes
resource "aws_cloudwatch_event_rule" "every_20_minutes" {
  name                = "${var.project_name}-every-20-minutes"
  description         = "Triggers Lambda function every 20 minutes"
  schedule_expression = "rate(20 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target_every_20_minutes" {
  rule      = aws_cloudwatch_event_rule.every_20_minutes.name
  target_id = "lambda-schedule-every-20-minutes"
  arn       = aws_lambda_function.lambda_function.arn
  input     = jsonencode({ "schedule" : "every_20_min" })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda_every_20_minutes" {
  statement_id  = "AllowExecutionFromCloudWatchEvery20Minutes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_20_minutes.arn
}

# CloudWatch Event rule for twice a day (noon and midnight)
resource "aws_cloudwatch_event_rule" "twice_a_day" {
  name                = "${var.project_name}-twice-a-day"
  description         = "Triggers Lambda function twice a day at noon and midnight"
  schedule_expression = "cron(0 12,0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target_twice_a_day" {
  rule      = aws_cloudwatch_event_rule.twice_a_day.name
  target_id = "lambda-schedule-twice-a-day"
  arn       = aws_lambda_function.lambda_function.arn
  input     = jsonencode({ "schedule" : "2_times_a_day" })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda_twice_a_day" {
  statement_id  = "AllowExecutionFromCloudWatchTwiceADay"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.twice_a_day.arn
}

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