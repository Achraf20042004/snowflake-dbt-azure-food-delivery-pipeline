resource "snowflake_storage_integration" "azure_int" {
  name                      = "AZURE_STORAGE_INT"
  storage_provider          = "AZURE"
  azure_tenant_id           = var.azure_tenant_id
  storage_allowed_locations = ["azure://fooddeliverydwhadls.blob.core.windows.net/raw/"]
  enabled                   = true
  comment                   = "Integration between Snowflake and Azure ADLS raw container"
}
