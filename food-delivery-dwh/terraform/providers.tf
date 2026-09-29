terraform {
  required_version = ">= 1.5"
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.20"
    }


      azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  role              = "SYSADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.private_key_path)

preview_features_enabled = [
    "snowflake_file_format_resource",
    "snowflake_stage_resource",
    "snowflake_storage_integration_resource",

  ]
}




provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}