resource "random_string" "random" {
  length  = 6
  upper   = false
  number  = false
  special = false
}

locals {
  storage_account_name = substr(lower(replace(var.stack_name, "/[-_]/", "")), 0, 18)
}

resource "azurerm_storage_account" "example" {
  name                     = "${local.storage_account_name}${random_string.random.result}"
  resource_group_name      = var.rg_name
  location                 = var.rg_location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "testing"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.stack_name}-vnet"
  address_space       = ["10.0.0.0/20"]
  location            = var.rg_location
  resource_group_name = var.rg_name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.stack_name}-subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/22"]
}