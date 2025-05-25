# IF a resource group was not provided, create a new one
module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.2.0"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

# Generate a random string if a project prefix was not provided
resource "random_string" "prefix" {
  count   = var.project_prefix != "" ? 0 : 1
  length  = 4
  special = false
  upper   = false
  numeric = false
}

# Generate a new SSH key if one was not provided
resource "tls_private_key" "ssh" {
  count     = var.existing_ssh_key != "" ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Add a new SSH key to the region if one was created
resource "ibm_is_ssh_key" "generated_key" {
  count          = var.existing_ssh_key != "" ? 0 : 1
  name           = "${local.prefix}-${var.region}-key"
  public_key     = tls_private_key.ssh.0.public_key_openssh
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

# Write private key to file if it was generated
resource "null_resource" "create_private_key" {
  count = var.existing_ssh_key != "" ? 0 : 1
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.ssh.0.private_key_pem}' > ./'${local.prefix}'.pem
      chmod 400 ./'${local.prefix}'.pem
    EOT
  }
}



module "bastion" {
  source            = "./modules/compute"
  prefix            = "${local.prefix}-bastion"
  resource_group_id = module.resource_group.resource_group_id
  vpc_id            = ibm_is_vpc.vpc.id
  subnet_id         = ibm_is_subnet.dmz.id
  security_group_id = module.dmz_security_group.security_group_id
  zone              = local.vpc_zones[0].zone
  user_data         = file("${path.module}/init.yaml")
  ssh_key_ids       = local.ssh_key_ids
  tags              = local.tags
}

resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.prefix}-${local.vpc_zones[0].zone}-bastion-ip"
  target         = module.bastion.primary_network_interface
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

module "vault_servers" {
  count             = length(data.ibm_is_zones.regional.zones)
  source            = "./modules/compute"
  prefix            = "${local.prefix}-vault-${count.index}"
  resource_group_id = module.resource_group.resource_group_id
  vpc_id            = ibm_is_vpc.vpc.id
  subnet_id         = ibm_is_subnet.vault[count.index].id
  security_group_id = module.vault_security_group.security_group_id
  zone              = local.vpc_zones[count.index].zone
  ssh_key_ids       = local.ssh_key_ids
  user_data         = file("${path.module}/vault_userdata_script.sh")
  tags              = local.tags
}
