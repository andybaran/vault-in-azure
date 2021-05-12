#!/bin/bash
# NB this file will be executed as root by cloud-init.
# NB to troubleshoot the execution of this file, you can:
#      1. access the virtual machine boot diagnostics pane in the azure portal.
#      2. ssh into the virtual machine and execute:
#           * sudo journalctl
#           * sudo journalctl -u cloud-final
set -euxo pipefail

ip_address="$(ip addr show eth0 | perl -n -e'/ inet (\d+(\.\d+)+)/ && print $1')"

# install postgres
# NB execute `apt-cache madison vault` to known the available versions.
# can't hurt to add hashicorp repo
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get install postgresql jq -y

echo "listen_address = '*'" >> /etc/postgresql/10/main/postgresql.conf
echo "host    all   all 0.0.0.0/0   md5" >> /etc/postgresql/10/main/pg_hba.conf
systemctl restart postgresql.service