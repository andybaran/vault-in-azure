## template:jinja
#cloud-config
package_upgrade: true
write_files: 
  - encoding: text/plain
    path : /etc/vault.d/vault.hclic
    owner: vault:vault
    permissions: '0770'
    content: ${vault_license}
  - encoding: text/plain
    path: /etc/vault.d/vault.hcl
    owner: vault:vault
    permissions: '0770'
    content : |
      ui = true
      storage "raft" {
        path = "/opt/vault/data"
        node_id = "${vault_vm_name}"
      }
      api_addr = "https://127.0.0.1:8200"
      cluster_addr = "https://127.0.0.1:8201"
      license_path = "/etc/vault.d/vault.hclic"
      listener "tcp" {
        address = "0.0.0.0:8200"
        tls_cert_file = "/opt/vault/tls/tls.crt"
        tls_key_file = "/opt/vault/tls/tls.key"
      }
runcmd:
  - [vault, audit, enable, syslog, tag="vault", facility="AUTH"]