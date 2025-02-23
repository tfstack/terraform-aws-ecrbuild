# Terraform ECR Build Module

This Terraform module creates and manages an **AWS ECR repository** with an automated **CodeBuild pipeline** for building and pushing container images.

## Features

- ✅ **Creates an ECR repository** with an auto-generated suffix for uniqueness
- ✅ **Builds and pushes container images to ECR** using AWS CodeBuild
- ✅ **Supports automated builds via CodePipeline**
- ✅ **Manages IAM roles and permissions** for secure access
- ✅ **Stores source code in an S3 bucket for reproducibility**

---

## Usage Example

```hcl
terraform {
  required_version = ">= 1.0"
}

# Generate a random suffix for uniqueness
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "ecr_build" {
  source = "../.."

  # Naming Configuration
  repository_name         = "test-ecr-build"
  suffix                  = random_string.suffix.result
  app_name                = "hello"
  repository_force_delete = true

  # Storage Paths
  container_source_path  = "${path.module}/external/source"
  container_archive_path = "${path.module}/external"

  # CodeBuild Configuration
  codebuild_timeout          = 10
  codebuild_compute_type     = "BUILD_GENERAL1_SMALL"
  codebuild_image            = "aws/codebuild/standard:5.0"
  codebuild_environment_type = "LINUX_CONTAINER"
  codebuild_buildspec        = "buildspec.yml"

  codebuild_env_vars = {
    ENVIRONMENT = "dev"
    PROJECT     = "example-project"
  }

  # CodePipeline Configuration
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
            S3Bucket             = module.s3_bucket.bucket_id
            S3ObjectKey          = "${var.app_name}.zip"
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
            ProjectName = module.ecr_build.base_name
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

# Outputs
output "all_module_outputs" {
  description = "All outputs from the ECR Build module"
  value       = module.ecr_build
}
```

---

## Inputs

| Name                          | Type          | Description |
|--------------------------------|--------------|-------------|
| `repository_name`              | `string`     | Base name for the ECR repository |
| `suffix`                       | `string`     | Unique suffix for resource names |
| `repository_force_delete`       | `bool`       | Allow forced deletion of the ECR repository |
| `app_name`                     | `string`     | Name of the application |
| `container_source_path`         | `string`     | Path to local source directory |
| `container_archive_path`        | `string`     | Path where ZIP archive will be stored |
| `codebuild_timeout`             | `number`     | Timeout for CodeBuild in minutes |
| `codebuild_compute_type`        | `string`     | Compute size for CodeBuild |
| `codebuild_image`               | `string`     | CodeBuild image |
| `codebuild_environment_type`    | `string`     | Type of build environment |
| `codebuild_buildspec`           | `string`     | Path to buildspec file |
| `codebuild_env_vars`            | `map(string)` | Additional environment variables for CodeBuild |
| `codepipeline_stages`           | `list(object)` | Stages and actions for the CodePipeline |

---

## Outputs

| Name                | Description |
|---------------------|-------------|
| `suffix`           | Random suffix used for resource naming |
| `base_name`        | Base name of the created resources |
| `app_name`         | Name of the application |
| `repository_name`  | Name of the ECR repository |
| `container_source_path` | Path to the local container source |
| `container_archive_path` | Path where the ZIP archive is stored |

---

## Deployment Steps

### **1️⃣ Initialize Terraform**

```sh
terraform init
```

### **2️⃣ Apply the Configuration**

```sh
terraform apply -auto-approve
```

### **3️⃣ View Outputs**

```sh
terraform output
```

### **4️⃣ Destroy Resources**

```sh
terraform destroy -auto-approve
```

---

## Notes

- **The repository name must be globally unique**, so a random suffix is added.
- **CodePipeline will automatically trigger builds when source changes in S3**.
- **S3 bucket stores source code and allows pipeline integration**.
- **Logging and versioning are supported for security and tracking**.

---

## License

This module is released under the **MIT License**.
