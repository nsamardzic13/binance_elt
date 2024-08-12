data "aws_secretsmanager_secret" "bq_secret" {
  arn = var.bq_secret_arn
}

resource "aws_ecs_cluster" "ecs" {
  name = "${var.project_name}-ecs"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "${var.project_name}-ecs-task-logs"
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