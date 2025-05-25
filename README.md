# HashiCorp Vault on IBM Cloud

This project deploys a 3-node HashiCorp Vault cluster with high availability across IBM Cloud VPC availability zones, featuring a load balancer and bastion host for secure access.

## Architecture

```
Internet → Load Balancer (TCP/8200) → 3 Vault Servers (1 per zone)
                                    ↓
                                Bastion Host (SSH)
```

- **3 Vault Servers**: One per availability zone for high availability
- **Application Load Balancer**: TCP load balancer on port 8200
- **Bastion Host**: Secure SSH access for administration
- **Consul Backend**: Provides HA storage and leader election

## Prerequisites

- IBM Cloud Account with VPC permissions
- Terraform >= 1.0
- `mise` task runner ([installation](https://mise.jdx.dev/getting-started.html))
- SSH key pair

## Quick Start

### 1. Configure Variables

Copy and edit the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings:

```hcl
# REQUIRED: Your existing SSH key name in IBM Cloud
existing_ssh_key = "my-ssh-key-name"

# OPTIONAL: Customize deployment
region = "us-south"
project_prefix = "vault-demo"
vault_instance_profile = "bx2-2x8"

# Security: Restrict SSH access
ssh_allowed_ips = ["YOUR.IP.ADDRESS.HERE/32"]
```

### 2. Deploy Infrastructure

```bash
# Initialize and apply
mise run apply
```

### 3. Initialize Vault

```bash
# SSH to bastion host
mise run ssh-bastion

# Initialize Vault cluster (run once)
mise run vault-init

# Unseal all Vault nodes (interactive)
mise run vault-unseal
```

### 4. Access Vault

```bash
# Check cluster status
mise run vault-status

# Open Vault UI
mise run vault-ui

# Or access directly at: http://<load-balancer-hostname>:8200/ui
```

## Available Tasks

```bash
# Infrastructure
mise run apply          # Deploy infrastructure
mise run destroy        # Destroy all resources
mise run status         # Show deployment status

# Vault Operations  
mise run vault-init     # Initialize Vault cluster
mise run vault-unseal   # Unseal Vault nodes
mise run vault-status   # Check cluster health

# Access
mise run ssh-bastion             # SSH to bastion
VAULT_NODE=1 mise run ssh-vault  # SSH to specific vault node

# Utilities
mise run info           # Show URLs and connection info
mise run help           # Show all available tasks
```

## Project Structure

```
├── main.tf                 # Main infrastructure resources  
├── vpc.tf                  # VPC, subnets, gateways
├── security.tf             # Security groups
├── load-balancer.tf        # Load balancer configuration
├── data.tf                 # Data sources
├── locals.tf               # Local values
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── vault-userdata.sh       # Vault installation script
├── .mise.toml              # Task runner configuration
└── modules/compute/        # Reusable compute module
```

## Network Ports

| Service | Port | Purpose |
|---------|------|---------|
| Vault API | 8200 | Client connections via load balancer |
| Vault Cluster | 8201 | Inter-node communication |
| Consul | 8300-8302 | Consul cluster communication |
| SSH | 22 | Administrative access via bastion |

## Security

- **Network Segmentation**: Separate security groups for each tier
- **Bastion Access**: No direct SSH to vault servers  
- **Load Balancer**: Public access only through load balancer
- **Intra-cluster**: Self-referencing security group rules

## Next Steps

After successful deployment:

1. **Configure Authentication**: Set up LDAP, OIDC, or other auth methods
2. **Enable TLS**: Integrate with IBM Secrets Manager for SSL certificates  
3. **Set up Monitoring**: Add health checks and alerting
4. **Backup Strategy**: Implement Consul snapshot backups
5. **Auto-unseal**: Configure with IBM Key Protect

## Cleanup

To destroy all resources:

```bash
mise run destroy
```

---

**Note**: This configuration uses HTTP (port 8200) for simplicity. For production, enable TLS termination at the load balancer with proper SSL certificates.