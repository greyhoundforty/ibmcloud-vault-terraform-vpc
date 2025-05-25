# Get Ubuntu image
data "ibm_is_image" "base" {
  name = var.base_image
}
