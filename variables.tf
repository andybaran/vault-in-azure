variable "rg_name" {
  type = string
}

variable "admin_username" {
  type    = string
}

variable "vault_vm_name" {
  type = string
}

variable "vault_version" {
  type = string
}

variable "vault_license" {
  type = string
}

variable "postgres_vm_name" {
  type = string
}

variable "ARM_CLIENT_SECRET" {
  type = string
}

variable "ARM_SUBSCRIPTION_ID" {
  type = string
}

variable "ARM_CLIENT_ID" {
  type = string
}
variable "ARM_TENANT_ID" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_keyvault_name" {
  type = string
}

variable "azure_bastion_host_name" {
  type = string
}

variable "windows_vm_name" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "tfc_agent_token" {
  type = string
}

variable "tfc_agent_name" {
  type = string
}

variable "common-azure-tags" {
  description = "common azure tags"
  type        = map(any)
  default = {
    owner = "andy.baran",
    se-region = "AMER - West E2 - R2",
    purpose = "Vault Enterprise Demo",
    ttl = "168",
    hc-internet-facing = "False"
  }
}

variable "active_directory_domain" {
  type = string 
  default = "mydomain.local"
}

variable "active_directory_netbios_name" {
  type = string
  default = "mydomain"
}