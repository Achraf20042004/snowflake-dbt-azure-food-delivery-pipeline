variable "snowflake_organization" { type = string }
variable "snowflake_account"      { type = string }
variable "snowflake_user"         { type = string }
variable "azure_subscription_id" { type = string }
variable "private_key_path" {
  type      = string
  sensitive = true
}
variable "azure_location" {
  type    = string
  default = "francecentral"
}
variable "azure_tenant_id" {
  type      = string
  sensitive = true
}
