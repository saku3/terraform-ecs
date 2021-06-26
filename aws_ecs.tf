resource "aws_ecs_cluster" "main" {
  name = "${var.project}-ecs-cluster"
}

resource "aws_ecs_service" "main" {
  name                              = "${var.project}-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = ["${aws_subnet.private_subnet_1.id}", "${aws_subnet.private_subnet_2.id}"]
    security_groups  = ["${aws_security_group.container.id}"]
    assign_public_ip = "false"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "${var.project}-container"
    container_port   = "8080"
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }
}

resource "aws_ecs_task_definition" "main" {
  family = "${var.project}-task-definition"

  requires_compatibilities = [
    "FARGATE"
  ]

  cpu    = 256
  memory = 512

  network_mode = "awsvpc"

  task_role_arn = aws_iam_role.ecs_task_role.arn

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = templatefile("./json/container_definitions.tpl.json",
    {
      account_id     = "${data.aws_caller_identity.current.id}",
      container_name = var.project,
      repository_url = aws_ecr_repository.main.name,
      tag            = var.image_tag
    }
  )
}


resource "aws_security_group" "container" {
  name        = "${var.project}-container-sg"
  description = "container sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    security_groups = [
      aws_security_group.alb.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-container-sg"
  }
}
