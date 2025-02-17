############################################
# General Outputs
############################################

output "base_name" {
  description = "The computed base name used for resources"
  value       = local.base_name
}

############################################
# ECR Repository Outputs
############################################

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

############################################
# S3 Bucket Outputs
############################################

output "s3_bucket_name" {
  description = "The name of the S3 bucket storing application source"
  value       = module.s3_bucket.bucket_id
}

output "s3_object_key" {
  description = "The key of the uploaded application source ZIP in S3"
  value       = aws_s3_object.this.key
}

############################################
# IAM Role Outputs
############################################

output "iam_role_codebuild" {
  description = "IAM role ARN used by CodeBuild"
  value       = aws_iam_role.codebuild.arn
}

output "iam_role_codepipeline" {
  description = "IAM role ARN used by CodePipeline"
  value       = aws_iam_role.codepipeline.arn
}

############################################
# CloudWatch Logs Outputs
############################################

output "cloudwatch_log_group" {
  description = "CloudWatch log group for CodeBuild"
  value       = aws_cloudwatch_log_group.codebuild.name
}

############################################
# CodeBuild Outputs
############################################

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.this.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.this.arn
}

############################################
# CodePipeline Outputs
############################################

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.this.name
}

output "codepipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.this.arn
}
