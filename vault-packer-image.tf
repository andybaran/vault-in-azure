data "hcp_packer_image" "packer_image_vault" {
  bucket_name = "VaultEnt"
  channel         = "latest"
  cloud_provider  = "azure"
  region          = "eastus"
}

data "cloudinit_config" "vault-cloudinit" {
  gzip = false
  base64_encode = true
  part {
    content = templatefile("vault-packer-image-cloudinit.tpl", {vault_license = var.vault_license, vault_vm_name = var.vault_vm_name})
    content_type = "text/jinja2"
  }
}

resource "azurerm_linux_virtual_machine" "vault-packer-vm" {
  name                = "akb-vault-packer"
  resource_group_name = azurerm_resource_group.vault-rg.name
  location            = azurerm_resource_group.vault-rg.location
  size                = "Standard_D4a_v4" #https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
  disable_password_authentication = false
  admin_username      = var.admin_username
  admin_password = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.vault-packer-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data         = data.cloudinit_config.vault-cloudinit.rendered

  source_image_id = data.hcp_packer_image.packer_image_vault.cloud_image_id

  # Use these commented out lines to try to deploy directly instead of via Packer
  # source_image_id = "/subscriptions/14692f20-9428-451b-8298-102ed4e39c2a/resourceGroups/akb-tfc/providers/Microsoft.Compute/images/akb-vault-1216"
  # source_image_reference {
  #   publisher = "Canonical"
  #   offer     = "UbuntuServer"
  #   sku       = "18.04-LTS"
  #   version   = "latest"
  # }

  tags = var.common-azure-tags

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_virtual_machine_extension" "vault-monitor-extension" {
  name = "azure-monitor-extension"
  virtual_machine_id = azurerm_linux_virtual_machine.vault-packer-vm.id
  publisher = "Microsoft.Azure.Monitor"
  type = "AzureMonitorLinuxAgent"
  type_handler_version = "1.25"
}

resource "azurerm_monitor_data_collection_rule_association" "vault-packer-dcra" {
  name                    = "vault-packer-dcra"
  target_resource_id      = azurerm_linux_virtual_machine.vault-packer-vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vault-dcr.id
  description             = "Packer Vault Image DCRA"
}