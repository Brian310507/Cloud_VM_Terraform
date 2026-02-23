# Affiche l'ID du groupe de ressources
output "resource_group_id" {
  value = azurerm_resource_group.tp_rg.id
}

# Affiche l'IP publique du Load Balancer (C'est elle que vous devez curl)
output "load_balancer_public_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}

# Affiche les IPs privées des VMs
output "vms_private_ips" {
  value = azurerm_network_interface.vm_nic[*].private_ip_address
}