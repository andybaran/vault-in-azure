resource "azurerm_bastion_host" "gatekeeper" {
  name                = var.azure_bastion_host_name
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name

  ip_configuration {
    name                 = "${var.azure_bastion_host_name}-bastion-pub-ip"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastion-ip.id
  }
  tags = var.common-azure-tags
}