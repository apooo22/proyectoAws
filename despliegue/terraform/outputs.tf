output "user_pool_id" {
  description = "ID del User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "client_id" {
  description = "ID del cliente de la app"
  value       = aws_cognito_user_pool_client.client.id
}

output "cognito_login_url" {
  description = "URL de login con Hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${var.region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.client.id}&response_type=code&scope=email+openid+profile&redirect_uri=${var.callback_url}"
}

output "api_gateway_url" {
  description = "URL del endpoint protegido"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/admin"
}