resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/agente_pelambres"
  retention_in_days = 14
  tags              = var.common_tags_icsara
}
resource "aws_cloudwatch_log_group" "ecs_logs_4cpu" {
  name              = "/ecs/agente_pelambres_4cpu"
  retention_in_days = 14
  tags              = var.common_tags_icsara
}

resource "aws_cloudwatch_log_group" "ecs_logs_test_s3" {
  name              = "/ecs/agente_test_s3"
  retention_in_days = 14
  tags              = var.common_tags_icsara
}

resource "aws_cloudwatch_log_group" "ecs_logs_pelambres_cb_op" {
  name              = "/ecs/agente_pelambres_cb_op"
  retention_in_days = 14
  tags              = var.common_tags_icsara
}

resource "aws_cloudwatch_log_group" "ecs_logs_pelambres_evu_op" {
  name              = "/ecs/agente_pelambres_evu_op"
  retention_in_days = 14
  tags              = var.common_tags_icsara
}


resource "aws_cloudwatch_log_group" "ecs_logs_pelambres_cb_cierre" {
  name              = "/ecs/agente_pelambres_cb_cierre"
  retention_in_days = 14
  tags              = var.common_tags_icsara
}

resource "aws_cloudwatch_log_group" "ecs_logs_pelambres_evu_cierre" {
  name              = "/ecs/agente_pelambres_evu_cierre"
  retention_in_days = 14
  tags              = var.common_tags_icsara
}




resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRoleAgentePelambres"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Role para la tarea (acceso a S3)
resource "aws_iam_role" "task_role" {
  name = "ecsTaskS3WriteRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_write_policy" {
  name = "S3WritePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObjectAcl"
      ],
      Resource = [
        "arn:aws:s3:::*",
        "arn:aws:s3:::*/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_write" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.s3_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "logs_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "mi_cluster" {
  name = "cluster-agente-pelambres"
  tags = var.common_tags_icsara
}

resource "aws_ecs_task_definition" "mi_tarea" {
  family                   = "task-agente-pelambres"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  container_definitions = jsonencode([{
    name      = "agente-pelambres"
    image     = var.ecr_image
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }, # Valor por defecto
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}


resource "aws_ecs_task_definition" "pelambres_4cpu" {
  family                   = "task-agente-pelambres-4cpu"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "4096"
  memory                   = "8192"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  ephemeral_storage {
    size_in_gib = 25
  }

  container_definitions = jsonencode([{
    name      = "agente-pelambres-4cpu"
    image     = var.ecr_image
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }, # Valor por defecto
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_4cpu.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "test_s3" {
  family                   = "task-agente-test-s3"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  container_definitions = jsonencode([{
    name      = "agente-test-s3"
    image     = var.ecr_image_test_s3
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_test_s3.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "pelambres_cb_op" {
  family                   = "task-agente-pelambres-cb-op"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  container_definitions = jsonencode([{
    name      = "agente-pelambres-cb-op"
    image     = var.ecr_image_pelambres_cb_op
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_pelambres_cb_op.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "pelambres_evu_op" {
  family                   = "task-agente-pelambres-evu-op"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  container_definitions = jsonencode([{
    name      = "agente-pelambres-evu-op"
    image     = var.ecr_image_pelambres_evu_op
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_pelambres_evu_op.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "pelambres_cb_cierre" {
  family                   = "task-agente-pelambres-cb-cierre"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  container_definitions = jsonencode([{
    name      = "agente-pelambres-cb-cierre"
    image     = var.ecr_image_pelambres_cb_cierre
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_pelambres_cb_cierre.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}


resource "aws_ecs_task_definition" "pelambres_evu_cierre" {
  family                   = "task-agente-pelambres-evu-cierre"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  container_definitions = jsonencode([{
    name      = "agente-pelambres-evu-cierre"
    image     = var.ecr_image_pelambres_evu_cierre
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_pelambres_evu_cierre.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# Infraestuctura para Mauro Pupio
resource "aws_cloudwatch_log_group" "ecs_logs_mpupio" {
  name              = "/ecs/agente_mpupio"
  retention_in_days = 30
  tags              = var.common_tags_icsara
}

resource "aws_cloudwatch_log_group" "ecs_logs_mpupio_cb" {
  name              = "/ecs/agente_mpupio_cb"
  retention_in_days = 30
  tags              = var.common_tags_icsara
}

resource "aws_cloudwatch_log_group" "ecs_logs_mpupio_evu" {
  name              = "/ecs/agente_mpupio_evu"
  retention_in_days = 30
  tags              = var.common_tags_icsara
}

resource "aws_ecs_cluster" "cluster-agente-mpupio" {
  name = "cluster-agente-mpupio"
}

resource "aws_ecs_task_definition" "task-agente-mpupio" {
  family                   = "task-agente-mpupio"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  container_definitions = jsonencode([{
    name      = "agente-mpupio"
    image     = var.ecr_image_mpupio
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_mpupio.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "task-agente-mpupio-cb" {
  family                   = "task-agente-mpupio-cb"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  ephemeral_storage {
    size_in_gib = 25
  }

  container_definitions = jsonencode([{
    name      = "agente-mpupio-cb"
    image     = var.ecr_image_mpupio_cb
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_mpupio_cb.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}
resource "aws_ecs_task_definition" "task-agente-mpupio-evu" {
  family                   = "task-agente-mpupio-evu"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  ephemeral_storage {
    size_in_gib = 25
  }

  container_definitions = jsonencode([{
    name      = "agente-mpupio-evu"
    image     = var.ecr_image_mpupio_evu
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_mpupio_evu.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# recursos para modelo Choapa
#creación de logs de CloudWatch
resource "aws_cloudwatch_log_group" "ecs_logs_choapa" {
  name              = "/ecs/agente_choapa"
  retention_in_days = 30
  tags              = var.common_tags_icsara
}
resource "aws_cloudwatch_log_group" "ecs_logs_choapa_cb" {
  name              = "/ecs/agente_choapa_cb"
  retention_in_days = 30
  tags              = var.common_tags_icsara
}
resource "aws_cloudwatch_log_group" "ecs_logs_choapa_evu" {
  name              = "/ecs/agente_choapa_evu"
  retention_in_days = 30
  tags              = var.common_tags_icsara
}
#crear Cluster ECS para el modelo Choapa
resource "aws_ecs_cluster" "cluster_agente_choapa" {
  name = "cluster-agente-choapa"
  tags = var.common_tags_icsara
}

resource "aws_ecs_task_definition" "task_agente_choapa" {
  family                   = "task-agente-choapa"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  container_definitions = jsonencode([{
    name      = "agente-choapa"
    image     = var.ecr_image_choapa
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }, # Valor por defecto
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_choapa.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "task_agente_choapa_cb" {
  family                   = "task-agente-choapa-cb"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  ephemeral_storage {
    size_in_gib = 25
  }

  container_definitions = jsonencode([{
    name      = "agente-choapa-cb"
    image     = var.ecr_image_choapa_cb
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }, # Valor por defecto
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_choapa_cb.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "task_agente_choapa_evu" {
  family                   = "task-agente-choapa-evu"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn
  tags                     = var.common_tags_icsara

  ephemeral_storage {
    size_in_gib = 25
  }

  container_definitions = jsonencode([{
    name      = "agente-choapa-evu"
    image     = var.ecr_image_choapa_evu
    essential = true
    command   = ["/bin/bash", "/app/entrypoint.sh"]
    environment = [
        { name = "ID_PARAMETRO", value = var.ID_PARAMETRO }, # Valor por defecto
        ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_choapa_evu.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}
