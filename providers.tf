terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-contentgen-temp-dev01"
    storage_account_name = "statfstatecontentgentemp"
    container_name       = "tfstatecontentgentemp"
    key                  = "contentgen-temp-dev01.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  subscription_id = "554bc026-bca6-4f59-b5a4-659820404e80"
}
