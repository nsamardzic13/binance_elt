resource "aws_sns_topic" "tf_sns_topic" {
  name = "${var.project_name}-sns"
}

resource "aws_sns_topic_subscription" "tf_user_updates_sqs_target" {
  topic_arn = aws_sns_topic.tf_sns_topic.arn
  protocol  = "email"
  endpoint  = var.sns_email_address
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.tf_sns_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
        "events.amazonaws.com",
      ]
    }

    resources = [aws_sns_topic.tf_sns_topic.arn]
  }
}