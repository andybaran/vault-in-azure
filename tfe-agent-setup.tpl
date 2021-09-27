#!/bin/bash
set -v
echo "beginning init"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update && sudo apt-get install vault docker-ce docker-ce-cli containerd.io -y

# probaly don't want to do this in prod and limit it to a specific user.
echo export TFC_AGENT_TOKEN="${tfc_agent_token}" | sudo tee -a /etc/profile
echo export TFC_AGENT_NAME="${tfc_agent_name}" | sudo tee -a /etc/profile
sudo usermod -aG docker ubuntu
source /etc/profile
docker run -d --restart unless-stopped --name tfc-agent -e TFC_AGENT_TOKEN -e TFC_AGENT_NAME hashicorp/tfc-agent:latest
echo "end init"