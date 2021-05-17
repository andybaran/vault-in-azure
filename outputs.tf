############ Outputs

output "private-key-pem" {
  value       = tls_private_key.ssh-key.private_key_pem
  description = "Private key in PEM format"
  sensitive = false
}

output "openssh-public-key" {
  value       = tls_private_key.ssh-key.public_key_openssh
  description = "OpenSSH Public Key"
  sensitive = false
}

output "public-key-md5" {
  value       = tls_private_key.ssh-key.public_key_fingerprint_md5
  description = "Public key MD5"
  sensitive = false
}

output "key_vault_name" {
  value = azurerm_key_vault.vault-vault.name
  sensitive = false
}
