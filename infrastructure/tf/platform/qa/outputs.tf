output "stage_id" {
  value = aws_apigatewayv2_stage.stage_resource.id
}

output "api_gateway_id" {
  value = aws_apigatewayv2_api.api_gateway.id
}

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store the lambda authorizer function code."

  value = aws_s3_bucket.lambda_bucket.id
}

output "authorizer_function_name" {
  description = "Name of the custom authorizer Lambda function."

  value = aws_lambda_function.lambda_authorizer.function_name
}

output "lambda_authorizer_cloudwatch_log_group" {
  description = "Cloudwatch log group for for the test lambda authorizer"

  value = aws_cloudwatch_log_group.lambda_authorizer
}

output "api_gateway_domain_name" {
  description = "FQDN of the API Gateway"

  value = aws_apigatewayv2_domain_name.domain_resource
}

output "aws_apigatewayv2_api_api_gateway" {
  description = "The api-gateway info"
  value       = aws_apigatewayv2_api.api_gateway
}

output "aws_apigatewayv2_api_mapping_api_mapping_resource" {
  description = "The api-gateway dns mapping"
  value       = aws_apigatewayv2_api_mapping.api_mapping_resource
}
