resource "ibm_is_instance" "compute" {
  name           = var.prefix
  vpc            = var.vpc_id
  image          = data.ibm_is_image.base.id
  profile        = var.instance_profile
  resource_group = var.resource_group_id

  metadata_service {
    enabled            = var.metadata_service_enabled
    protocol           = "https"
    response_hop_limit = 5
  }

  boot_volume {
    name = "${var.prefix}-boot-volume"
  }

  primary_network_interface {
    subnet            = var.subnet_id
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [var.security_group_id]
  }
  user_data = var.user_data
  zone      = var.zone
  keys      = var.ssh_key_ids
  tags      = var.tags
}