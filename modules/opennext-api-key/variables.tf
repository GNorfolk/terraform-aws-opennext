/**
 * Common Variables
 **/
variable "prefix" {
  type        = string
  description = "Prefix for created resource IDs"
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to all created resources"
  default     = {}
}

variable "region" {
  type        = string
  description = "The deployment region to be used by the AWS provider."
}

/**
 * API Key Variables
 **/
variable "existing_api_key_id" {
  type        = string
  description = "The ID of an existing API Gateway API key to use. When null, a new API key is created."
  default     = null
}
