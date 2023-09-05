output "private_ip" {
  value = azurerm_network_interface.public.private_ip_address
}
