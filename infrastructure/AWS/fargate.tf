data "aws_secretsmanager_secret" "bq_secret" {
  arn = var.bq_secret_arn
}

resource "aws_ecs_cluster" "ecs" {
  name = "${var.project_name}-ecs"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "${var.project_name}-ecs-task-logs"
  retention_in_days = 7
}
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.iam_role.arn
  task_role_arn            = aws_iam_role.iam_role.arn
  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-ecs-task"
      image     = var.image_name
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.id
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "${var.project_name}-ecs-task-log"
        }
      }
      environment = [
        {
          name  = "GCP_PROJECT"
          value = var.gcp_project
        },
        {
          name  = "GCP_BIGQUERY_DATASET"
          value = var.gcp_dataset
        }
      ],
      secrets = [{
        "name" : "SERVICE_ACCOUNT_JSON",
        "valueFrom" : "${data.aws_secretsmanager_secret.bq_secret.arn}"
      }]
    }
  ])
}

resource "aws_cloudwatch_event_rule" "ecs_schedule_rule" {
  name                = "${var.project_name}-ecs-daily-schedule"
  description         = "Run ECS task daily at 2 AM"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "ecs_task_target" {
  rule     = aws_cloudwatch_event_rule.ecs_schedule_rule.name
  arn      = aws_ecs_cluster.ecs.arn
  role_arn = aws_iam_role.iam_role.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.ecs_task.arn
    task_count          = 1
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = aws_subnet.public_subnet[*].id
      security_groups  = ["${aws_security_group.tf_ecs_security_group.id}"]
      assign_public_ip = true
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_task_failure" {
  alarm_name          = "${var.project_name}-ecs-task-failure-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EcsTaskFailures"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "${aws_ecs_cluster.ecs.name} failed"
  alarm_actions       = [aws_sns_topic.tf_sns_topic.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs.name
  }
}

resource "aws_cloudwatch_event_rule" "container_stopped_rule" {
  name        = "${var.project_name}-container-stopped"
  description = "Notification for containers with exit code of 1 (error)."

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ecs"
  ],
  "detail-type": [
    "ECS Task State Change"
  ],
  "detail": {
    "lastStatus": [
      "STOPPED"
    ],
    "stoppedReason": [
      "Essential container in task exited"
    ],
    "clusterArn" : [
      "${aws_ecs_cluster.ecs.arn}"
    ],
    "containers": {
      "exitCode": [
        {
          "anything-but": 0
        }
      ]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.container_stopped_rule.name
  target_id = "SendEmail"
  arn       = aws_sns_topic.tf_sns_topic.arn
}