resource "aws_cloudwatch_event_rule" "tf_cw_event_rule" {
  name        = "${var.project_name}-cw-event-rule-lambda"
  description = "Trigger on Lambda function invocation status changes"
  event_pattern = jsonencode({
    source      = ["aws.lambda"]
    detail-type = ["Lambda Function Invocation Result"]
    detail = {
      functionName = ["${aws_lambda_function.lambda_function.function_name}"]
      status       = ["FAILED", "TIMEOUT"]
    }
  })
}

resource "aws_sns_topic" "tf_binance_lambda" {
  name = "${var.project_name}-sns-lambda"
}

resource "aws_sns_topic_subscription" "tf_user_updates_sqs_target" {
  topic_arn = aws_sns_topic.tf_binance_lambda.arn
  protocol  = "email"
  endpoint  = var.sns_email_address
}

resource "aws_cloudwatch_event_target" "tf_indexads_sns_target_sfn" {
  target_id = "${var.project_name}-sns-target-lambda"
  rule      = aws_cloudwatch_event_rule.tf_cw_event_rule.name
  arn       = aws_sns_topic.tf_binance_lambda.arn
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