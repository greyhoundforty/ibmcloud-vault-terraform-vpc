#!/bin/bash

# HashiCorp Vault Installation and Configuration Script
# This script will be executed during instance boot
# Variables: vault_role, zone, instance_id

set -e

# Configuration variables
VAULT_VERSION="1.15.4"
VAULT_USER="vault"
VAULT_CONFIG_DIR="/etc/vault.d"
VAULT_DATA_DIR="/opt/vault/data"
VAULT_LOG_DIR="/var/log/vault"
CONSUL_VERSION="1.17.1"

# Instance metadata
VAULT_ROLE="${vault_role}"
ZONE="${zone}"
INSTANCE_ID="${instance_id}"
NODE_NAME="vault-${zone}-${instance_id}"

# Get instance metadata
PRIVATE_IP=$(curl -s http://169.254.169.254/metadata/v1/instance/network-interfaces/0/ipv4/address)
INSTANCE_UUID=$(curl -s http://169.254.169.254/metadata/v1/instance/id)

# Update system
apt-get update
apt-get install -y curl unzip jq

# Create vault user
useradd --system --home /etc/vault.d --shell /bin/false vault

# Create directories
mkdir -p $VAULT_CONFIG_DIR $VAULT_DATA_DIR $VAULT_LOG_DIR
chown -R vault:vault $VAULT_CONFIG_DIR $VAULT_DATA_DIR $VAULT_LOG_DIR

#===========================================
# Install HashiCorp Vault
#===========================================
cd /tmp
curl -fsSL https://releases.hashicorp.com/vault/$${VAULT_VERSION}/vault_$${VAULT_VERSION}_linux_amd64.zip -o vault.zip
unzip vault.zip
mv vault /usr/local/bin/
chmod +x /usr/local/bin/vault

# Set capabilities
setcap cap_ipc_lock=+ep /usr/local/bin/vault

#===========================================
# Install Consul for Backend Storage
#===========================================
curl -fsSL https://releases.hashicorp.com/consul/$${CONSUL_VERSION}/consul_$${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
unzip consul.zip
mv consul /usr/local/bin/
chmod +x /usr/local/bin/consul

# Create consul user and directories
useradd --system --home /etc/consul.d --shell /bin/false consul
mkdir -p /etc/consul.d /opt/consul/data /var/log/consul
chown -R consul:consul /etc/consul.d /opt/consul/data /var/log/consul

#===========================================
# Configure Consul (Backend for Vault)
#===========================================
cat > /etc/consul.d/consul.hcl <<EOF
datacenter = "vault-dc"
data_dir = "/opt/consul/data"
log_level = "INFO"
node_name = "$${NODE_NAME}-consul"
bind_addr = "$${PRIVATE_IP}"
client_addr = "127.0.0.1"

# Cluster configuration - Updated for 3 nodes (1 per zone)
retry_join = [
  "10.240.64.4",   # Zone 1 - First available IP in vault subnet
  "10.240.128.4",  # Zone 2 - First available IP in vault subnet
  "10.240.192.4"   # Zone 3 - First available IP in vault subnet
]

# Enable clustering
bootstrap_expect = 3
server = true

# UI and API
ui_config {
  enabled = true
}

# Performance
performance {
  raft_multiplier = 1
}

# Logging
enable_syslog = true
log_file = "/var/log/consul/"
log_rotate_duration = "24h"
log_rotate_max_files = 7

# ACL (Basic security)
acl = {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
}

# Encryption
encrypt = "$(consul keygen)"
EOF

# Create Consul systemd service
cat > /etc/systemd/system/consul.service <<EOF
[Unit]
Description=Consul
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

#===========================================
# Configure Vault
#===========================================
cat > $VAULT_CONFIG_DIR/vault.hcl <<EOF
# Vault Configuration for High Availability Deployment

# Storage backend (Consul)
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
  token   = ""
  
  # HA Settings
  check_timeout = "5s"
  max_parallel  = "128"
  
  # TLS (disabled for simplicity in this example)
  tls_skip_verify = true
}

# Listener configuration
listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "$${PRIVATE_IP}:8201"
  tls_disable     = true
  
  # For production, enable TLS:
  # tls_cert_file = "/etc/vault.d/tls/vault.crt"
  # tls_key_file  = "/etc/vault.d/tls/vault.key"
  # tls_min_version = "tls12"
}

# High Availability
ha_storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
  token   = ""
}

# Cluster configuration
cluster_addr = "http://$${PRIVATE_IP}:8201"
api_addr     = "http://$${PRIVATE_IP}:8200"
node_id      = "$${NODE_NAME}"

# Disable mlock for containers/VMs
disable_mlock = true

# Logging
log_level = "INFO"
log_format = "json"

# UI
ui = true

# Plugin directory
plugin_directory = "/etc/vault.d/plugins"

# Performance settings
default_lease_ttl = "168h"
max_lease_ttl = "720h"

# Telemetry (optional)
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

# Seal configuration (for production, use auto-unseal)
# seal "awskms" {
#   region     = "us-west-2"
#   kms_key_id = "alias/vault-unseal-key"
# }
EOF

# Create Vault systemd service
cat > /etc/systemd/system/vault.service <<EOF
[Unit]
Description=HashiCorp Vault
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target consul.service
ConditionFileNotEmpty=$VAULT_CONFIG_DIR/vault.hcl

[Service]
Type=notify
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=$VAULT_CONFIG_DIR/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

#===========================================
# Set up log rotation
#===========================================
cat > /etc/logrotate.d/vault <<EOF
$VAULT_LOG_DIR/*.log {
    daily
    missingok
    rotate 52
    compress
    notifempty
    create 640 vault vault
    postrotate
        /bin/kill -HUP \`cat /var/run/vault.pid 2> /dev/null\` 2> /dev/null || true
    endscript
}
EOF

#===========================================
# Create helper scripts
#===========================================
# Vault status script
cat > /usr/local/bin/vault-status.sh <<'EOF'
#!/bin/bash
export VAULT_ADDR="http://127.0.0.1:8200"
echo "=== Vault Status ==="
vault status
echo
echo "=== Consul Members ==="
consul members
EOF
chmod +x /usr/local/bin/vault-status.sh

# Vault initialization script (run manually after deployment)
cat > /usr/local/bin/vault-init.sh <<'EOF'
#!/bin/bash
export VAULT_ADDR="http://127.0.0.1:8200"

if [ "$1" = "init" ]; then
    echo "Initializing Vault..."
    vault operator init -key-shares=5 -key-threshold=3 > /tmp/vault-keys.txt
    echo "Vault keys saved to /tmp/vault-keys.txt"
    echo "Please secure these keys!"
elif [ "$1" = "unseal" ]; then
    echo "Unsealing Vault..."
    echo "Please provide unseal keys:"
    vault operator unseal
    vault operator unseal
    vault operator unseal
else
    echo "Usage: $0 [init|unseal]"
    echo "  init   - Initialize a new Vault cluster"
    echo "  unseal - Unseal Vault (provide 3 keys)"
fi
EOF
chmod +x /usr/local/bin/vault-init.sh

#===========================================
# Enable and start services
#===========================================
systemctl daemon-reload

# Start Consul first
systemctl enable consul
systemctl start consul

# Wait for Consul to be ready
sleep 30

# Start Vault
systemctl enable vault
systemctl start vault

#===========================================
# Setup monitoring (optional)
#===========================================
# Install CloudWatch agent for monitoring (if needed)
# This would be specific to your monitoring requirements

#===========================================
# Final status check
#===========================================
sleep 10

echo "=== Installation Complete ==="
echo "Node: $NODE_NAME"
echo "Role: $VAULT_ROLE"
echo "Zone: $ZONE"
echo "Private IP: $PRIVATE_IP"
echo ""
echo "Services Status:"
systemctl is-active consul
systemctl is-active vault
echo ""
echo "To check status: /usr/local/bin/vault-status.sh"
echo "To initialize Vault (first time only): /usr/local/bin/vault-init.sh init"
echo "To unseal Vault: /usr/local/bin/vault-init.sh unseal"
echo ""
echo "=== Important Security Notes ==="
echo "1. This configuration uses HTTP (not HTTPS) for simplicity"
echo "2. For production, enable TLS encryption"
echo "3. Use auto-unseal with cloud KMS"
echo "4. Configure proper authentication methods"
echo "5. Set up audit logging"
echo "6. Implement backup and disaster recovery"
echo ""
echo "Vault UI will be available at: http://<load-balancer-ip>:8200/ui"