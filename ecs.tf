data "aws_ecs_task_definition" "ecs_task_definition" {
  task_definition = aws_ecs_task_definition.ecs_task_definition.family
  depends_on      = [aws_ecs_task_definition.ecs_task_definition]
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name               = local.name
  tags               = local.tags
  
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_provider" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecr_repository" "ecs_ecr" {
  name = local.name
  tags = local.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecs_ecr_lifecycle_policy" {
  repository = local.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

module "ecs_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.1"

  container_name  = local.name
  container_image = "${aws_ecr_repository.ecs_ecr.repository_url}:latest"

  port_mappings = [{
    hostPort : 3006,
    protocol : "tcp",
    containerPort : 3006
    }
  ]

  environment = [
    {
      name  = "FASTIFY_ADDRESS"
      value = "0.0.0.0"
    },
    {
      name  = "FASTIFY_PORT"
      value = "3006"
    },
    {
      name  = "LOG_LEVEL"
      value = "debug"
    },
    {
      name  = "DB_HOST"
      value = module.db.db_instance_address
    },
    {
      name  = "DB_PORT"
      value = "5432"
    },
    {
      name  = "DB_USER"
      value = "tf_admin"
    },
    {
      name  = "DB_PASSWORD"
      value = "masteruser"
    },
    {
      name  = "DB_DATABASE"
      value = "tf"
    }
  ]

  log_configuration = {
    logDriver : "awslogs",
    options : {
      awslogs-group : aws_cloudwatch_log_group.ecs_log_group.name,
      awslogs-region : "us-east-1"
      awslogs-stream-prefix : "ecs"
    }
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = local.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  task_role_arn      = aws_iam_role.ecs_role.arn
  execution_role_arn = aws_iam_role.ecs_role.arn

  container_definitions = module.ecs_container_definition.json_map_encoded_list
  tags                  = local.tags

}

resource "aws_ecs_service" "ecs_service" {
  name    = local.name
  tags    = local.tags
  cluster = aws_ecs_cluster.ecs_cluster.id

  # NOTE: this track the latest ACTIVE revision as it could have been modified in a pipeline outside of Terrafom 
  task_definition = "${aws_ecs_task_definition.ecs_task_definition.family}:${max(aws_ecs_task_definition.ecs_task_definition.revision, data.aws_ecs_task_definition.ecs_task_definition.revision)}"

  desired_count          = "2"
  enable_execute_command = true
  propagate_tags         = "SERVICE"
  launch_type            = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_sg.id]
    subnets         = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg_http.arn
    container_name   = local.name
    container_port   = 3006
  }

  # NOTE: ignore any changes to that count caused externally (e.g. ASG)
  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${local.name}/ecs"
  tags = local.tags
}

resource "aws_iam_role" "ecs_role" {
  name = "${local.name}-ecs"
  tags = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_managed_policy" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "alb" {
  name            = local.name
  tags            = local.tags
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = module.vpc.public_subnets
}

resource "aws_security_group" "ecs_sg" {
  name   = "${local.name}-ecs"
  description = "SG for ECS"
  tags   = local.tags
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "alb_sg" {
  name   = "${local.name}-alb"
  description = "SG for ALB"
  tags   = local.tags
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "alb_sg_rule_egress_wildcard" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow egress all TCP traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_sg_rule_ingress_http" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow access from the world to HTTP"
  type              = "ingress"
  from_port         = 3006
  to_port           = 3006
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_target_group" "alb_tg_http" {
  name        = local.name
  tags        = local.tags
  vpc_id      = module.vpc.vpc_id
  port        = "3006"
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path = "/graphiql"
  }
}

resource "aws_lb_listener" "alb_listener_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 3006
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_http.arn
  }

}

resource "aws_security_group_rule" "ecs_sg_rule_ingress_http" {
  security_group_id        = aws_security_group.ecs_sg.id
  description              = "Allow access from ALB to Fargate"
  type                     = "ingress"
  from_port                = 3006
  to_port                  = 3006
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "ecs_sg_rule_egress_wildcard" {
  security_group_id = aws_security_group.ecs_sg.id
  description       = "Allow access from Fargate to Internet (for ECR)"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}