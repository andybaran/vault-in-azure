############ Outputs

output "azurerm_rg_name" {
  value = azurerm_resource_group.vault-rg.name
  sensitive = false
}

output "azurerm_rg_location" {
  value = azurerm_resource_group.vault-rg.location
  sensitive = false
}

output "azurerm_vnet_id" {
  value = azurerm_virtual_network.vault-net.id
  sensitive = false
}

output "azurerm_subnet" {
  value = azurerm_subnet.vault-subnet.id
  sensitive = false 
}