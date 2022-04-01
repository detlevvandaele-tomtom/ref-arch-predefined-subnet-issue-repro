output "subnet_name" {
  value = azurerm_subnet.subnet.name
}

output "subnet_rg" {
  value = azurerm_subnet.subnet.resource_group_name
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}