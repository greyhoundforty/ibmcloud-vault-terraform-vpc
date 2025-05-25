module "dmz_security_group" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.7.0"
  add_ibm_cloud_internal_rules = true
  vpc_id                       = ibm_is_vpc.vpc.id
  resource_group               = module.resource_group.resource_group_id
  security_group_name          = "${local.prefix}-dmz-sg"
  security_group_rules = [
    {
      name      = "remote-ssh-inbound"
      direction = "inbound"
      remote    = var.ssh_allowed_ips
      tcp = {
        port_min = 22
        port_max = 22
      }
    },
    {
      name      = "icmp-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      icmp = {
        type = 8
        code = 1
      }
    },
    {
      name      = "allow-all-inbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
    }
  ]
}

module "load_balancer_security_group" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.7.0"
  add_ibm_cloud_internal_rules = true
  vpc_id                       = ibm_is_vpc.vpc.id
  resource_group               = module.resource_group.resource_group_id
  security_group_name          = "${local.prefix}-lb-sg"
  security_group_rules = [
    {
      name      = "allow-https-inbound-for-clients"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name      = "allow-all-inbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
    }
  ]
}


module "vault_security_group" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.7.0"
  add_ibm_cloud_internal_rules = true
  vpc_id                       = ibm_is_vpc.vpc.id
  resource_group               = module.resource_group.resource_group_id
  security_group_name          = "${local.prefix}-dmz-sg"
  security_group_rules = [
    {
      name      = "remote-ssh-inbound-from-dmz"
      direction = "inbound"
      remote    = module.dmz_security_group.security_group_id
      tcp = {
        port_min = 22
        port_max = 22
      }
    },
    {
      name      = "vault-api-from-lb"
      direction = "inbound"
      remote    = module.load_balancer_security_group.security_group_id
      tcp = {
        port_min = 8200
        port_max = 8200
      }
    },
    {
      name      = "allow-all-inbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
    }
  ]
}

# Allow intra-cluster communication (TCP/8201)
# resource "ibm_is_security_group_rule" "vault_cluster_communication" {
#   group     = ibm_is_security_group.vault_servers.id
#   direction = "inbound"
#   remote    = ibm_is_security_group.vault_servers.id
#   tcp {
#     port_min = 8201
#     port_max = 8201
#   }
# }
