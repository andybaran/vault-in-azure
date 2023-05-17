variable "vault_license" {
    type = string
    default = "yourmama"
}




data "cloudinit_config" "vault-cloudinit" {
  gzip = false
  base64_encode = true
  part {
    content = templatefile("vault-packer-image-cloudinit.tpl", {vault_license = var.vault_license})
    content_type = "text/jinja2"
  }
}