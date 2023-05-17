/* // the `exit_code_hack` is to keep the VM Extension resource happy
locals {
  import_command       = "Import-Module ADDSDeployment"
  password_command     = "$password = ConvertTo-SecureString ${var.admin_password} -AsPlainText -Force"
  install_ad_command   = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
  configure_ad_command = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.active_directory_domain} -DomainNetbiosName ${var.active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
  shutdown_command     = "shutdown -r -t 10"
  exit_code_hack       = "exit 0"
  powershell_command   = "${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"
}

// NOTE: we **highly recommend** not using this configuration for your Production Environment
// this provisions a single node configuration with no redundancy.
resource "azurerm_virtual_machine_extension" "create-active-directory-forest" {
  name                 = "create-active-directory-forest"
  virtual_machine_id = azurerm_windows_virtual_machine.windows-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  tags = var.common-azure-tags

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
} */