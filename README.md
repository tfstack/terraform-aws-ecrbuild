# terraform-aws-ecrbuild

Terraform module for automating Docker image builds and pushes to ECR using AWS CodeBuild triggered by S3 events

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.84.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.84.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | tfstack/ecr/aws | n/a |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | tfstack/s3/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [archive_file.this](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/resources/file) | resource |
| [aws_cloudwatch_log_group.codebuild](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_codebuild_project.this](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.this](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/codepipeline) | resource |
| [aws_iam_policy.codebuild](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_policy) | resource |
| [aws_iam_role.codebuild](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.codebuild](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/s3_object) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/data-sources/caller_identity) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | The name of the CodeDeploy application | `string` | n/a | yes |
| <a name="input_codebuild_buildspec"></a> [codebuild\_buildspec](#input\_codebuild\_buildspec) | Path to the buildspec file | `string` | `"buildspec.yml"` | no |
| <a name="input_codebuild_compute_type"></a> [codebuild\_compute\_type](#input\_codebuild\_compute\_type) | CodeBuild compute type | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| <a name="input_codebuild_env_vars"></a> [codebuild\_env\_vars](#input\_codebuild\_env\_vars) | Additional environment variables for CodeBuild | `map(string)` | `{}` | no |
| <a name="input_codebuild_environment_type"></a> [codebuild\_environment\_type](#input\_codebuild\_environment\_type) | Type of CodeBuild environment | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_codebuild_image"></a> [codebuild\_image](#input\_codebuild\_image) | CodeBuild Docker image | `string` | `"aws/codebuild/standard:5.0"` | no |
| <a name="input_codebuild_timeout"></a> [codebuild\_timeout](#input\_codebuild\_timeout) | Build timeout in minutes | `number` | `10` | no |
| <a name="input_codepipeline_stages"></a> [codepipeline\_stages](#input\_codepipeline\_stages) | List of CodePipeline stages and actions | <pre>list(object({<br/>    name = string<br/>    actions = list(object({<br/>      name             = string<br/>      category         = string<br/>      owner            = string<br/>      provider         = string<br/>      version          = string<br/>      input_artifacts  = optional(list(string))<br/>      output_artifacts = optional(list(string))<br/>      configuration    = map(string)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_container_archive_path"></a> [container\_archive\_path](#input\_container\_archive\_path) | Path to store the archived ZIP file for the container build | `string` | n/a | yes |
| <a name="input_container_source_path"></a> [container\_source\_path](#input\_container\_source\_path) | Path to the local directory containing the container source | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Retention period for CloudWatch logs in days | `number` | `30` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the provider. Defaults to ap-southeast-2 if not specified. | `string` | `"ap-southeast-2"` | no |
| <a name="input_repository_force_delete"></a> [repository\_force\_delete](#input\_repository\_force\_delete) | Set to true to allow forced deletion of the ECR repository on destroy | `bool` | `false` | no |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Base name for the repository and associated resources | `string` | n/a | yes |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Optional suffix for resource names | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_base_name"></a> [base\_name](#output\_base\_name) | The computed base name used for resources |
| <a name="output_cloudwatch_log_group"></a> [cloudwatch\_log\_group](#output\_cloudwatch\_log\_group) | CloudWatch log group for CodeBuild |
| <a name="output_codebuild_project_arn"></a> [codebuild\_project\_arn](#output\_codebuild\_project\_arn) | ARN of the CodeBuild project |
| <a name="output_codebuild_project_name"></a> [codebuild\_project\_name](#output\_codebuild\_project\_name) | Name of the CodeBuild project |
| <a name="output_codepipeline_arn"></a> [codepipeline\_arn](#output\_codepipeline\_arn) | ARN of the CodePipeline |
| <a name="output_codepipeline_name"></a> [codepipeline\_name](#output\_codepipeline\_name) | Name of the CodePipeline |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | URL of the ECR repository |
| <a name="output_iam_role_codebuild"></a> [iam\_role\_codebuild](#output\_iam\_role\_codebuild) | IAM role ARN used by CodeBuild |
| <a name="output_iam_role_codepipeline"></a> [iam\_role\_codepipeline](#output\_iam\_role\_codepipeline) | IAM role ARN used by CodePipeline |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | The name of the S3 bucket storing application source |
| <a name="output_s3_object_key"></a> [s3\_object\_key](#output\_s3\_object\_key) | The key of the uploaded application source ZIP in S3 |
