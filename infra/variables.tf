variable "aws_region" {
  description = "AWS region for the demo infrastructure"
  type        = string
  default     = "eu-central-1"
}

variable "app_name" {
  description = "Base name for the demo app"
  type        = string
  default     = "cicd-demo"
}

variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "initial_image_tag" {
  description = "Initial image tag used when creating App Runner services"
  type        = string
  default     = "bootstrap"
}