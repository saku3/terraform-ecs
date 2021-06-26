resource "aws_lb" "lb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    "${aws_security_group.alb.id}",
  ]

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    enabled = true
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  default_action {
    target_group_arn = aws_lb_target_group.blue.arn
    type             = "forward"
  }
  certificate_arn = aws_acm_certificate.cert.arn
}

resource "aws_lb_target_group" "blue" {
  name        = "${var.project}-blue-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "green" {
  name        = "${var.project}-green-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "http"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-alb-sg"
  }
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "${var.project}-alblogs-${random_string.s3_unique_key.result}"
  policy = templatefile("json/access_log_policy.tpl.json",
    {
      bucket_name = "${var.project}-alblogs-${random_string.s3_unique_key.result}",
      account_id  = "${data.aws_caller_identity.current.id}"
    }
  )

  versioning {
    enabled = false
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 7
    }
  }
}
