terraform {
  required_version = ">= 1.0"
}

# Generate a random string as suffix
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  region                 = "ap-southeast-2"
  repository_name        = "test-ecr-build"
  base_name              = "${local.repository_name}-${random_string.suffix.result}"
  app_name               = "hello"
  container_source_path  = "${path.module}/external/source"
  container_archive_path = "${path.module}/external"
}

# Output suffix for use in tests
output "suffix" {
  value = random_string.suffix.result
}

output "base_name" {
  value = local.base_name
}

output "app_name" {
  value = local.app_name
}

output "region" {
  value = local.region
}

output "repository_name" {
  value = local.repository_name
}

output "container_source_path" {
  value = local.container_source_path
}

output "container_archive_path" {
  value = local.container_archive_path
}
