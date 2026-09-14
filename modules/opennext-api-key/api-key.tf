resource "aws_api_gateway_api_key" "this" {
  count = var.existing_api_key_id == null ? 1 : 0
  name  = var.prefix
}

data "aws_api_gateway_api_key" "existing" {
  count = var.existing_api_key_id == null ? 0 : 1
  id    = var.existing_api_key_id
}

locals {
  api_key_id    = var.existing_api_key_id == null ? aws_api_gateway_api_key.this[0].id : data.aws_api_gateway_api_key.existing[0].id
  api_key_value = var.existing_api_key_id == null ? aws_api_gateway_api_key.this[0].value : data.aws_api_gateway_api_key.existing[0].value
}
