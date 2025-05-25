resource "ibm_is_vpc" "vpc" {
  name                        = "${local.prefix}-vpc"
  resource_group              = module.resource_group.resource_group_id
  address_prefix_management   = var.default_address_prefix
  default_network_acl_name    = "${local.prefix}-default-nacl"
  default_security_group_name = "${local.prefix}-default-sg"
  default_routing_table_name  = "${local.prefix}-default-rt"
  tags                        = local.tags
}


resource "ibm_is_public_gateway" "gateway" {
  count          = length(data.ibm_is_zones.regional.zones)
  name           = "${local.prefix}-pgw-zone-${count.index + 1}"
  resource_group = module.resource_group.resource_group_id
  vpc            = ibm_is_vpc.vpc.id
  zone           = local.vpc_zones[count.index].zone
  tags           = concat(local.tags, ["zone:${local.vpc_zones[count.index].zone}"])
}

resource "ibm_is_subnet" "dmz" {
  name                     = "${local.prefix}-dmz-subnet"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[0].zone
  total_ipv4_address_count = "16"
  public_gateway           = ibm_is_public_gateway.gateway.0.id
  tags                     = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_subnet" "vault" {
  count                    = length(data.ibm_is_zones.regional.zones)
  name                     = "${local.prefix}-vault-subnet-${count.index + 1}"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[count.index].zone
  total_ipv4_address_count = "32"
  public_gateway           = ibm_is_public_gateway.gateway[count.index].id
  tags                     = concat(local.tags, ["zone:${local.vpc_zones[count.index].zone}"])
}