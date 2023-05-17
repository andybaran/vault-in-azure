## template:jinja
#cloud-config
package_upgrade: true
write_files: 
  - encoding: text/plain
    path : /etc/vault.d/license.hclic
    owner: vault:vault
    permissions: '0770'
    content: ${vault_license}