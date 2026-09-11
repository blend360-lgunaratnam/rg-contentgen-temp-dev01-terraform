data "azurerm_resource_group" "target" {
  name = "rg-contentgen-temp-dev01"
}

resource "azurerm_storage_account" "contentgen_documents" {
  name                     = "stacontentgentempdev01"
  resource_group_name      = data.azurerm_resource_group.target.name
  location                 = data.azurerm_resource_group.target.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}