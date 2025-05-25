# HashiCorp Vault High Availability Deployment on IBM Cloud
# Updated to match existing code patterns and use 3 nodes (1 per zone)

# Application Load Balancer
resource "ibm_is_lb" "vault_lb" {
  name            = "${local.prefix}-vault-load-balancer"
  subnets         = ibm_is_subnet.vault[*].id
  type            = "public"
  security_groups = [module.load_balancer_security_group.security_group_id]
  resource_group  = module.resource_group.resource_group_id

  tags = concat(local.tags, ["vault", "load-balancer"])
}

# Load Balancer Listener (TCP)
resource "ibm_is_lb_listener" "vault_tcp" {
  lb           = ibm_is_lb.vault_lb.id
  port         = 8200
  protocol     = "tcp"
  default_pool = ibm_is_lb_pool.vault_pool.id
}

# Load Balancer Pool
resource "ibm_is_lb_pool" "vault_pool" {
  name                = "${local.prefix}-vault-pool"
  lb                  = ibm_is_lb.vault_lb.id
  algorithm           = "round_robin"
  protocol            = "http"
  health_delay        = 60
  health_retries      = 5
  health_timeout      = 30
  health_type         = "http"
  health_monitor_url  = "/v1/sys/health"
  health_monitor_port = 8200
}

# Load Balancer Pool Members - 3 servers (1 per zone)
resource "ibm_is_lb_pool_member" "vault_members" {
  count          = length(data.ibm_is_zones.regional.zones)
  lb             = ibm_is_lb.vault_lb.id
  pool           = ibm_is_lb_pool.vault_pool.id
  port           = 8200
  target_address = module.vault_servers[count.index].primary_ip
  weight         = 50
}

# # Load Balancer Pool Members - 3 servers (1 per zone)
# resource "ibm_is_lb_pool_member" "vault_members" {
#   count          = length(data.ibm_is_zones.regional.zones)
#   lb             = ibm_is_lb.vault_lb.id
#   pool           = ibm_is_lb_pool.vault_pool.id
#   port           = 8200
#   target_address = module.vault_servers[count.index].primary_ip
#   weight         = 50
# }