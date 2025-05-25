# # Outputs
# output "load_balancer_hostname" {
#   description = "Load balancer hostname for client access"
#   value       = ibm_is_lb.vault_lb.hostname
# }

# output "load_balancer_public_ips" {
#   description = "Load balancer public IP addresses"
#   value       = ibm_is_lb.vault_lb.public_ips
# }

# output "vault_server_private_ips" {
#   description = "Private IP addresses of all Vault servers"
#   value = {
#     zone_a_1 = ibm_is_instance.vault_server_zone_a_1.primary_network_interface[0].primary_ip[0].address
#     zone_b_1 = ibm_is_instance.vault_server_zone_b_1.primary_network_interface[0].primary_ip[0].address
#     zone_b_2 = ibm_is_instance.vault_server_zone_b_2.primary_network_interface[0].primary_ip[0].address
#     zone_c_1 = ibm_is_instance.vault_server_zone_c_1.primary_network_interface[0].primary_ip[0].address
#     zone_c_2 = ibm_is_instance.vault_server_zone_c_2.primary_network_interface[0].primary_ip[0].address
#   }
# }

# output "vpc_id" {
#   description = "VPC ID"
#   value       = ibm_is_vpc.vault_vpc.id
# }

# output "subnet_ids" {
#   description = "Subnet IDs for each zone"
#   value = {
#     zone_a = ibm_is_subnet.vault_subnet_zone_a.id
#     zone_b = ibm_is_subnet.vault_subnet_zone_b.id
#     zone_c = ibm_is_subnet.vault_subnet_zone_c.id
#   }
# }