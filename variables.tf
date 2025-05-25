
variable "region" {
  description = "IBM Cloud region"
  type        = string
  default     = "us-south"
}

variable "ibmcloud_api_key" {
  description = "IBM Cloud API key for authentication"
  type        = string
  sensitive   = true
}

variable "existing_resource_group" {
  description = "Name of an existing resource group to use. If not set, a new resource group will be created."
  type        = string
  default     = ""
}

variable "vault_instance_profile" {
  description = "Instance profile for Vault servers"
  type        = string
  default     = "bx2-2x8" # 2 vCPUs, 8GB RAM
}

variable "base_image" {
  description = "Base image to use for the Vault servers"
  type        = string
  default     = ""
}

variable "project_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = ""
}

variable "existing_ssh_key" {
  description = "Name of an existing SSH key in the region. If not set, a new SSH key will be created."
  type        = string
}


variable "default_address_prefix" {
  description = "The address prefix to use for the VPC. Default is set to auto."
  type        = string
  default     = "auto"
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses allowed to SSH into the DMZ server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

