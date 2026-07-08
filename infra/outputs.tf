output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}

output "staging_service_arn" {
  value = aws_apprunner_service.staging.arn
}

output "production_service_arn" {
  value = aws_apprunner_service.production.arn
}

output "staging_url" {
  value = "https://${aws_apprunner_service.staging.service_url}"
}

output "production_url" {
  value = "https://${aws_apprunner_service.production.service_url}"
}