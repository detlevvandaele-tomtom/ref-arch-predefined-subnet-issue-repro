locals {
  name = "aks-issue-repro"
}

resource "azurerm_resource_group" "rg" {
  name     = "RG-weu-${local.name}"
  location = "West Europe"
}

module "networking" {
  source = "./networking"

  stack_name  = local.name
  rg_name     = azurerm_resource_group.rg.name
  rg_location = azurerm_resource_group.rg.location
}

module "aks" {
  source     = "./aks"
  depends_on = [module.networking]

  stack_name  = "${local.name}-cluster"
  rg_name     = azurerm_resource_group.rg.name
  location    = azurerm_resource_group.rg.location
  subnet_name = module.networking.subnet_name
  subnet_rg   = module.networking.subnet_rg
  vnet_name   = module.networking.vnet_name
}