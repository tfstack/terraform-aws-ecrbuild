# ----------------------------------------
# General Configuration
# ----------------------------------------
variable "region" {
  description = "AWS region for the provider. Defaults to ap-southeast-2 if not specified."
  type        = string
  default     = "ap-southeast-2"

  validation {
    condition     = can(regex("^([a-z]{2}-[a-z]+-\\d{1})$", var.region))
    error_message = "Invalid AWS region format. Example: 'us-east-1', 'ap-southeast-2'."
  }
}
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ----------------------------------------
# Resource Naming & Identifiers
# ----------------------------------------

variable "repository_name" {
  description = "Base name for the repository and associated resources"
  type        = string
}

variable "suffix" {
  description = "Optional suffix for resource names"
  type        = string
  default     = ""
}

variable "repository_force_delete" {
  description = "Set to true to allow forced deletion of the ECR repository on destroy"
  type        = bool
  default     = false
}

# ----------------------------------------
# Application & Storage Configuration
# ----------------------------------------

variable "app_name" {
  description = "The name of the CodeDeploy application"
  type        = string
}

variable "container_source_path" {
  description = "Path to the local directory containing the container source"
  type        = string
}

variable "container_archive_path" {
  description = "Path to store the archived ZIP file for the container build"
  type        = string
}


variable "log_retention_days" {
  description = "Retention period for CloudWatch logs in days"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3650
    error_message = "log_retention_days must be between 1 and 3650."
  }
}

# ----------------------------------------
# CodeBuild Configuration
# ----------------------------------------

variable "codebuild_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 10
}

variable "codebuild_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_image" {
  description = "CodeBuild Docker image"
  type        = string
  default     = "aws/codebuild/standard:5.0"
}

variable "codebuild_environment_type" {
  description = "Type of CodeBuild environment"
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "codebuild_buildspec" {
  description = "Path to the buildspec file"
  type        = string
  default     = "buildspec.yml"
}

variable "codebuild_env_vars" {
  description = "Additional environment variables for CodeBuild"
  type        = map(string)
  default     = {}
}

# ----------------------------------------
# CodePipeline Configuration
# ----------------------------------------

variable "codepipeline_stages" {
  description = "List of CodePipeline stages and actions"
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string
      owner            = string
      provider         = string
      version          = string
      input_artifacts  = optional(list(string))
      output_artifacts = optional(list(string))
      configuration    = map(string)
    }))
  }))
}
