output "vm_public_ip" {
  description = "Public IP of the API VM"
  value       = azurerm_public_ip.vm.ip_address
}

output "api_url" {
  description = "URL to reach the LearningSteps API"
  value       = "http://${azurerm_public_ip.vm.ip_address}:8000/docs"
}

output "postgresql_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "ssh_command" {
  description = "Command to SSH into the VM"
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.vm.ip_address}"
}
