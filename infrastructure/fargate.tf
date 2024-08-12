resource "aws_ecs_cluster" "ecs" {
  name = "${var.project_name}-ecs"
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.tf_indexads_role.arn
  task_role_arn            = aws_iam_role.tf_indexads_role.arn
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
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "${var.project_name}-ecs-task-logs"
}