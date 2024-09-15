data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../../lambda"
  output_path = "../../lambda.zip"
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

resource "aws_cloudwatch_metric_alarm" "lambda_errors_count_alarm" {
  alarm_name          = "${var.project_name}-lambda-error-count-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 900
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "${aws_lambda_function.lambda_function.function_name} failed"
  alarm_actions       = [aws_sns_topic.tf_sns_topic.arn]

  dimensions = {
    FunctionName = aws_lambda_function.lambda_function.function_name
  }
}
