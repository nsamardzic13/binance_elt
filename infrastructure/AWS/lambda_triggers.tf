# CloudWatch Event rule for every 30 minutes
resource "aws_cloudwatch_event_rule" "every_30_minutes" {
  name                = "${var.project_name}-every-30-minutes"
  description         = "Triggers Lambda function every 30 minutes"
  schedule_expression = "rate(30 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target_every_30_minutes" {
  rule      = aws_cloudwatch_event_rule.every_30_minutes.name
  target_id = "lambda-schedule-every-30-minutes"
  arn       = aws_lambda_function.lambda_function.arn
  input     = jsonencode({ "schedule" : "every_30_min" })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda_every_30_minutes" {
  statement_id  = "AllowExecutionFromCloudWatchEvery30Minutes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_30_minutes.arn
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