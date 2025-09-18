#!/bin/bash
set -e

# Update packages
apt-get update -y
apt-get upgrade -y
apt-get install -y unzip curl wget gnupg lsb-release apt-transport-https ca-certificates software-properties-common

# Install Docker (for Nomad jobs using Docker driver)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce
usermod -aG docker ubuntu

# Install Nomad
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y nomad

# Create Nomad config directory
mkdir -p /etc/nomad.d
chmod 755 /etc/nomad.d

# Fetch private IP dynamically from AWS metadata
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Nomad server config
cat <<EOF >/etc/nomad.d/server.hcl
data_dir  = "/opt/nomad"

server {
  enabled          = true
  bootstrap_expect = 1
}

bind_addr = "0.0.0.0"

advertise {
  http = "\$PRIVATE_IP:4646"
  rpc  = "\$PRIVATE_IP:4647"
  serf = "\$PRIVATE_IP:4648"
}
EOF

# Enable and start Nomad
systemctl enable nomad
systemctl restart nomad
