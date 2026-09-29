resource "azurerm_resource_group" "rg" {
  name     = "rg-food-delivery-dwh"
  location = var.azure_location
}

resource "azurerm_storage_account" "adls" {
  name                     = "fooddeliverydwhadls"   # must be globally unique, lowercase, 3-24 chars
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true                    # makes it ADLS Gen2
}

resource "azurerm_storage_container" "raw" {
  name                  = "raw"
  storage_account_id    = azurerm_storage_account.adls.id
  container_access_type = "private"
}

resource "azurerm_data_factory" "adf" {
  name                = "adf-food-delivery-dwh"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}