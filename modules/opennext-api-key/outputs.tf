output "api_key_id" {
  value = local.api_key_id
}

output "api_key_value" {
  value     = local.api_key_value
  sensitive = true
}
