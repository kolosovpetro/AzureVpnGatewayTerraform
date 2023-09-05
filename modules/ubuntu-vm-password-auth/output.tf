output "private_ip" {
  value = azurerm_network_interface.public.private_ip_address
}

output "username" {
  value = var.os_profile_admin_username
}
