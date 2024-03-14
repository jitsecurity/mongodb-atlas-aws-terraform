output "provider_id" {
  value = aws_vpc_endpoint.third_party_service.id
}

output "name" {
  value = var.name
}

output "endpoint_service_name" {
  value = var.service_name
}

output "endpoint_id" {
  value = var.endpoint_id
}