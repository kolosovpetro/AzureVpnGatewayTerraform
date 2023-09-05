output "vms_subnet_id" {
  value = azurerm_subnet.vms_subnet.id
}

output "vms_subnet_name" {
  value = azurerm_subnet.vms_subnet.name
}

output "vpn_subnet_id" {
  value = azurerm_subnet.vpn_subnet.id
}

output "vpn_subnet_name" {
  value = azurerm_subnet.vpn_subnet.name
}

output "vnet_name" {
  value = azurerm_virtual_network.public.name
}
