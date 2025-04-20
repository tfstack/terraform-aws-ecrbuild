run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "test_ecr_build" {
  variables {
    repository_name         = run.setup.repository_name
    app_name                = "hello"
    suffix                  = run.setup.suffix
    repository_force_delete = true

    container_source_path  = run.setup.container_source_path
    container_archive_path = run.setup.container_archive_path
    log_retention_days     = 7

    codebuild_timeout          = 10
    codebuild_compute_type     = "BUILD_GENERAL1_SMALL"
    codebuild_image            = "aws/codebuild/standard:5.0"
    codebuild_environment_type = "LINUX_CONTAINER"
    codebuild_buildspec        = "buildspec.yml"

    codebuild_env_vars = {
      ENVIRONMENT = "dev"
      PROJECT     = "example-project"
    }

    codepipeline_stages = [
      {
        name = "Source"
        actions = [
          {
            name             = "S3-Source"
            category         = "Source"
            owner            = "AWS"
            provider         = "S3"
            version          = "1"
            output_artifacts = ["source-output"]
            configuration = {
              S3Bucket             = run.setup.base_name
              S3ObjectKey          = "${run.setup.app_name}.zip"
              PollForSourceChanges = "true"
            }
          }
        ]
      },
      {
        name = "Build"
        actions = [
          {
            name            = "Build-Docker-Image"
            category        = "Build"
            owner           = "AWS"
            provider        = "CodeBuild"
            version         = "1"
            input_artifacts = ["source-output"]
            configuration = {
              ProjectName = run.setup.base_name
            }
          }
        ]
      }
    ]

    tags = {
      Environment = "dev"
      Project     = "example-project"
    }
  }

  # Assertions for ECR Repository
  assert {
    condition     = endswith(module.ecr.repository_url, run.setup.base_name)
    error_message = "ECR repository name does not match expected value."
  }

  assert {
    condition     = endswith(module.ecr.repository_arn, "repository/${run.setup.base_name}")
    error_message = "ECR repository ARN does not end with the expected repository name."
  }

  # Assertions for S3 Bucket
  assert {
    condition     = module.s3_bucket.bucket_arn == "arn:aws:s3:::${run.setup.base_name}"
    error_message = "S3 bucket ARN does not match expected value."
  }

  # Assertions for CodeBuild
  assert {
    condition     = aws_iam_role.codebuild.name == "${run.setup.base_name}-codebuild"
    error_message = "CodeBuild IAM role name does not match expected value."
  }

  assert {
    condition     = can(jsondecode(aws_iam_role.codebuild.assume_role_policy).Statement[0].Principal.Service == "codebuild.amazonaws.com")
    error_message = "CodeBuild IAM role is not assuming the correct service principal."
  }

  assert {
    condition     = aws_codebuild_project.this.name == run.setup.base_name
    error_message = "CodeBuild project name does not match expected value."
  }

  assert {
    condition     = aws_codebuild_project.this.environment[0].compute_type == "BUILD_GENERAL1_SMALL"
    error_message = "Compute type is not set correctly."
  }

  assert {
    condition     = aws_codebuild_project.this.environment[0].image == "aws/codebuild/standard:5.0"
    error_message = "Build image is not set correctly."
  }

  assert {
    condition     = aws_codebuild_project.this.environment[0].type == "LINUX_CONTAINER"
    error_message = "Build environment type is not Linux."
  }

  assert {
    condition     = aws_codebuild_project.this.build_timeout == 10
    error_message = "Build timeout is not set to 10 minutes."
  }

  # Assertions for CodePipeline
  assert {
    condition     = aws_codepipeline.this.name == run.setup.base_name
    error_message = "CodePipeline name does not match expected value."
  }
}
