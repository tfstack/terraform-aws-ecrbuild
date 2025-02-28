############################################
# Global Variables & Data Sources
############################################

locals {
  base_name = (
    var.suffix == "" ?
    var.repository_name :
    "${var.repository_name}-${var.suffix}"
  )
  files = fileset(var.container_source_path, "**")
  hash = md5(
    join(
      "",
      [for f in local.files : "${f}:${filemd5("${var.container_source_path}/${f}")}"]
    )
  )
}

data "aws_region" "this" {}
data "aws_caller_identity" "current" {}

############################################
# ECR Repository
############################################

module "ecr" {
  source = "tfstack/ecr/aws"

  region = var.region

  repository_name = local.base_name
  force_delete    = var.repository_force_delete

  tags = merge(var.tags, { Name = local.base_name })
}

############################################
# S3 Storage (Bucket & Source Upload)
############################################
module "s3_bucket" {
  source = "tfstack/s3/aws"

  region = var.region

  bucket_name   = var.repository_name
  bucket_suffix = var.suffix
  force_destroy = true
  tags          = merge(var.tags, { Name = local.base_name })
}
resource "archive_file" "this" {
  type        = "zip"
  source_dir  = var.container_source_path
  output_path = "${var.container_archive_path}/${var.app_name}.zip"
}

resource "aws_s3_object" "this" {
  bucket      = module.s3_bucket.bucket_id
  key         = "${var.app_name}.zip"
  source      = archive_file.this.output_path
  source_hash = local.hash
}

############################################
# IAM Roles & Policies
############################################

## IAM Role & Policy for CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "${local.base_name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codebuild" {
  name        = "${local.base_name}-codebuild"
  description = "Allows CodeBuild to build and push images to ECR."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ECRAuthAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPushAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = module.ecr.repository_arn
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          module.s3_bucket.bucket_arn,
          "${module.s3_bucket.bucket_arn}/*"
        ]
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          # codebuild appears to be always expecting log-group with `-build` suffix
          "arn:aws:logs:${data.aws_region.this.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.base_name}-build:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

## IAM Role & Policy for CodePipeline
resource "aws_iam_role" "codepipeline" {
  name = "${local.base_name}-codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codepipeline" {
  name        = "${local.base_name}-codepipeline"
  description = "Allows CodePipeline to trigger CodeBuild and access S3."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          module.s3_bucket.bucket_arn,
          "${module.s3_bucket.bucket_arn}/*"
        ]
      },
      {
        Sid    = "CodeBuildAccess"
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = aws_codebuild_project.this.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  policy_arn = aws_iam_policy.codepipeline.arn
  role       = aws_iam_role.codepipeline.name
}

############################################
# CloudWatch Log Group for CodeBuild
############################################

resource "aws_cloudwatch_log_group" "codebuild" {
  # codebuild appears to be always expecting log-group with `-build` suffix
  name              = "/aws/codebuild/${local.base_name}-build"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = local.base_name })
}

############################################
# CodeBuild Project (Docker Build & Push)
############################################

resource "aws_codebuild_project" "this" {
  name          = local.base_name
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = var.codebuild_timeout

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = var.codebuild_compute_type
    image           = var.codebuild_image
    type            = var.codebuild_environment_type
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPO"
      value = module.ecr.repository_url
    }

    dynamic "environment_variable" {
      for_each = var.codebuild_env_vars
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.base_name}-build"
      stream_name = "build"
    }
  }

  source {
    type      = "S3"
    location  = "${module.s3_bucket.bucket_id}/${var.app_name}.zip"
    buildspec = var.codebuild_buildspec
  }

  tags = merge(var.tags, { Name = local.base_name })
}

############################################
# CodePipeline Configuration (ECR Build Only)
############################################

resource "aws_codepipeline" "this" {
  name     = local.base_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = module.s3_bucket.bucket_id
    type     = "S3"
  }

  dynamic "stage" {
    for_each = var.codepipeline_stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = lookup(action.value, "input_artifacts", null)
          output_artifacts = lookup(action.value, "output_artifacts", null)
          configuration    = action.value.configuration
        }
      }
    }
  }

  depends_on = [
    aws_s3_object.this
  ]

  tags = merge(var.tags, { Name = local.base_name })
}
