## Variables with default values
variable "instance_profile" {
  description = "The profile to use for the compute hosts."
  type        = string
  default     = "cx3d-4x10"
}

variable "base_image" {
  description = "The name of the image to use for the compute hosts."
  type        = string
  default     = "ibm-ubuntu-24-04-2-minimal-amd64-1"
}

variable "metadata_service_enabled" {
  description = "Enable metadata service for the bastion host."
  type        = bool
  default     = true
}

variable "allow_ip_spoofing" {
  description = "Allow IP spoofing for the bastion host."
  type        = bool
  default     = false
}

## Variables provided to module by main.tf 
variable "prefix" {}
variable "vpc_id" {}
variable "resource_group_id" {}
variable "subnet_id" {}
variable "security_group_id" {}
variable "zone" {}
variable "ssh_key_ids" {}
variable "tags" {}
variable "user_data" {}
