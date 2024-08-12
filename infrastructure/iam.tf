resource "aws_iam_role" "iam_role" {
  name = "${var.project_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
      {
        "Action" = "sts:AssumeRole"
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "scheduler.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_role_policy" "combined_policy" {
  name = "CombinedIAMPolicy"
  role = aws_iam_role.iam_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:*",
          "s3:*",
          "sns:*",
          "events:*",
          "athena:*",
          "lambda:*",
          "secretsmanager:*",
          "iam:*",
          "ecs:*"
        ],
        Resource = "*"
      }
    ]
  })
}