module "orders_service" {
  source = "../ecs-app-service"

  environment_name          = local.full_environment_prefix
  service_name              = "orders"
  cluster_id                = aws_ecs_cluster.cluster.id
  ecs_deployment_controller = var.ecs_deployment_controller
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  security_group_ids        = [ aws_security_group.nsg_task.id, aws_security_group.orders.id ]
  lb_security_group_id      = aws_security_group.lb_sg.id
  sd_namespace_id           = aws_service_discovery_private_dns_namespace.sd.id
  cpu                       = 512
  memory                    = 1024
  health_check_path         = "/actuator/health"
  health_check_grace_period = 120
  fargate                   = var.fargate
  ssm_kms_policy_arn        = aws_iam_policy.ssm_kms.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "application",
    "image": "watchn/watchn-orders:${module.image_tag.image_tag}",
    "memory": 1024,
    "cpu": 512,
    "essential": true,
    "environment": [
      {
        "name": "SPRING_DATASOURCE_WRITER_URL",
        "value": "jdbc:mysql://${module.orders_rds.writer_endpoint}:3306/orders"
      },
      {
        "name": "SPRING_DATASOURCE_WRITER_USERNAME",
        "value": "${module.orders_rds.username}"
      },
      {
        "name": "SPRING_DATASOURCE_READER_URL",
        "value": "jdbc:mysql://${module.orders_rds.reader_endpoint}:3306/orders"
      },
      {
        "name": "SPRING_DATASOURCE_READER_USERNAME",
        "value": "${module.orders_rds.username}"
      },
      {
        "name": "SPRING_ACTIVEMQ_BROKERURL",
        "value": "${module.mq.wire_endpoint}"
      },
      {
        "name": "SPRING_ACTIVEMQ_USER",
        "value": "${module.mq.user}"
      },
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "value": "mysql,activemq,prod"
      },
      {
        "name": "JAVA_OPTS",
        "value": "-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/urandom"
      }
    ],
    "secrets": [
      {
        "name": "SPRING_DATASOURCE_WRITER_PASSWORD",
        "valueFrom": "${module.orders_rds.password_ssm_name}"
      },
      {
        "name": "SPRING_DATASOURCE_READER_PASSWORD",
        "valueFrom": "${module.orders_rds.password_ssm_name}"
      },
      {
        "name": "SPRING_ACTIVEMQ_PASSWORD",
        "valueFrom": "${module.mq.password_ssm_name}"
      }
    ],
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 8080
      }
    ],
    "healthCheck": {
      "command" : [ 
        "CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"
      ],
      "interval" : 30,
      "retries" : 3,
      "startPeriod" : 60,
      "timeout" : 10
    },
    "linuxParameters": {
      "capabilities": {
        "drop": ["ALL"]
      }
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.logs.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_security_group" "orders" {
  name_prefix = "${local.full_environment_prefix}-orders"
  vpc_id      = module.vpc.vpc_id

  description = "Marker SG for orders service"
}

resource "aws_security_group_rule" "orders_rds_ingress" {
  description = "Allow access from orders ECS task"

  type                      = "ingress"
  from_port                 = 3306
  to_port                   = 3306
  protocol                  = "tcp"
  source_security_group_id  = aws_security_group.orders.id
  security_group_id         = module.orders_rds.security_group_id
}

module "orders_rds" {
  source = "../aws-global-rds-mysql"

  environment_name = local.full_environment_prefix
  instance_name    = "orders"
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.database_subnets
  db_name          = "orders"
  ssm_key_id       = aws_kms_key.ssm_key.key_id
}

resource "aws_iam_role_policy" "orders_execution" {
  name = "${local.full_environment_prefix}-orders-execution"
  role = module.orders_service.execution_role_name

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": [
        "${module.orders_rds.password_ssm_arn}",
        "${module.mq.password_ssm_arn}"
      ]
    }
  ]
}
EOF
}