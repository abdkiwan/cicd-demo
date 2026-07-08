terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  repository_full_name = "${var.github_owner}/${var.github_repo}"

  common_tags = {
    Project = var.app_name
    Demo    = "cicd-masterclass"
  }
}

# ------------------------------------------------------------
# ECR repository: where GitHub Actions pushes Docker images
# ------------------------------------------------------------

resource "aws_ecr_repository" "app" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# ------------------------------------------------------------
# App Runner access role: allows App Runner to pull from ECR
# ------------------------------------------------------------

resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.app_name}-apprunner-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# ------------------------------------------------------------
# App Runner staging service
# ------------------------------------------------------------

resource "aws_apprunner_service" "staging" {
  service_name = "${var.app_name}-staging"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.app.repository_url}:${var.initial_image_tag}"
      image_repository_type = "ECR"

      image_configuration {
        port = "8000"

        runtime_environment_variables = {
          APP_ENV     = "staging"
          APP_NAME    = "CI/CD Demo API"
          APP_VERSION = var.initial_image_tag
        }
      }
    }

    auto_deployments_enabled = false
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/health"
  }

  instance_configuration {
    cpu    = "0.25 vCPU"
    memory = "0.5 GB"
  }

  tags = merge(local.common_tags, {
    Environment = "staging"
  })
}

# ------------------------------------------------------------
# App Runner production service
# ------------------------------------------------------------

resource "aws_apprunner_service" "production" {
  service_name = "${var.app_name}-production"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.app.repository_url}:${var.initial_image_tag}"
      image_repository_type = "ECR"

      image_configuration {
        port = "8000"

        runtime_environment_variables = {
          APP_ENV     = "production"
          APP_NAME    = "CI/CD Demo API"
          APP_VERSION = var.initial_image_tag
        }
      }
    }

    auto_deployments_enabled = false
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/health"
  }

  instance_configuration {
    cpu    = "0.25 vCPU"
    memory = "0.5 GB"
  }

  tags = merge(local.common_tags, {
    Environment = "production"
  })
}

# ------------------------------------------------------------
# GitHub OIDC provider in AWS
# ------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = local.common_tags
}

# ------------------------------------------------------------
# IAM role assumed by GitHub Actions
# ------------------------------------------------------------

resource "aws_iam_role" "github_actions_deploy" {
  name = "${var.app_name}-github-actions-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.repository_full_name}:*"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "${var.app_name}-github-actions-deploy-policy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRLogin"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "PushImagesToECR"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = aws_ecr_repository.app.arn
      },
      {
        Sid    = "DeployToAppRunner"
        Effect = "Allow"
        Action = [
          "apprunner:DescribeService",
          "apprunner:UpdateService",
          "apprunner:StartDeployment",
          "apprunner:ListOperations"
        ]
        Resource = [
          aws_apprunner_service.staging.arn,
          aws_apprunner_service.production.arn
        ]
      },
      {
        Sid    = "PassAppRunnerAccessRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.apprunner_ecr_access.arn
      }
    ]
  })
}