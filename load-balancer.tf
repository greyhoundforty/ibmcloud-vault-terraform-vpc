# Application Load Balancer
resource "ibm_is_lb" "vault_lb" {
  name = "vault-load-balancer"
  subnets = [
    ibm_is_subnet.vault_subnet_zone_a.id,
    ibm_is_subnet.vault_subnet_zone_b.id,
    ibm_is_subnet.vault_subnet_zone_c.id
  ]
  type            = "public"
  security_groups = [ibm_is_security_group.vault_lb.id]
  resource_group  = var.resource_group_id

  tags = ["vault", "load-balancer"]
}

# Load Balancer Listener (HTTPS)
resource "ibm_is_lb_listener" "vault_tcp" {
  lb           = ibm_is_lb.vault_lb.id
  port         = 8200
  protocol     = "tcp"
  default_pool = ibm_is_lb_pool.vault_pool.id

  # You would need to provide an SSL certificate
  # certificate_instance = var.certificate_crn
}

# Load Balancer Pool
resource "ibm_is_lb_pool" "vault_pool" {
  name                = "vault-pool"
  lb                  = ibm_is_lb.vault_lb.id
  algorithm           = "round_robin"
  protocol            = "tcp"
  health_delay        = 60
  health_retries      = 5
  health_timeout      = 30
  health_type         = "tcp"
  health_monitor_url  = "/v1/sys/health"
  health_monitor_port = 8200
}

# Load Balancer Pool Members
resource "ibm_is_lb_pool_member" "vault_member_zone_a_1" {
  lb     = ibm_is_lb.vault_lb.id
  pool   = ibm_is_lb_pool.vault_pool.id
  port   = 8200
  target = ibm_is_instance.vault_server_zone_a_1.primary_network_interface[0].primary_ip[0].address
  weight = 50
}

resource "ibm_is_lb_pool_member" "vault_member_zone_b_1" {
  lb     = ibm_is_lb.vault_lb.id
  pool   = ibm_is_lb_pool.vault_pool.id
  port   = 8200
  target = ibm_is_instance.vault_server_zone_b_1.primary_network_interface[0].primary_ip[0].address
  weight = 100 # Higher weight for active server
}

resource "ibm_is_lb_pool_member" "vault_member_zone_b_2" {
  lb     = ibm_is_lb.vault_lb.id
  pool   = ibm_is_lb_pool.vault_pool.id
  port   = 8200
  target = ibm_is_instance.vault_server_zone_b_2.primary_network_interface[0].primary_ip[0].address
  weight = 50
}

resource "ibm_is_lb_pool_member" "vault_member_zone_c_1" {
  lb     = ibm_is_lb.vault_lb.id
  pool   = ibm_is_lb_pool.vault_pool.id
  port   = 8200
  target = ibm_is_instance.vault_server_zone_c_1.primary_network_interface[0].primary_ip[0].address
  weight = 50
}

resource "ibm_is_lb_pool_member" "vault_member_zone_c_2" {
  lb     = ibm_is_lb.vault_lb.id
  pool   = ibm_is_lb_pool.vault_pool.id
  port   = 8200
  target = ibm_is_instance.vault_server_zone_c_2.primary_network_interface[0].primary_ip[0].address
  weight = 50
}