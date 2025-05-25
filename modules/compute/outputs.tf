output "primary_network_interface" {
  value = ibm_is_instance.compute.primary_network_interface[0].id
}

output "instance" {
  value = ibm_is_instance.compute[*]
}

output "primary_ip" {
  value = ibm_is_instance.compute.primary_network_interface[0].primary_ip[0].address
}