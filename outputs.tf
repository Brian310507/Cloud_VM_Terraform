output "vm_public_ips" {
  description = "Public IP addresses of the VMs"
  value       = azurerm_public_ip.pip[*].ip_address
}

output "lb_public_ip" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}