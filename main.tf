data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "public" {
  location = var.resource_group_location
  name     = "rg-p2s-vpn-${var.prefix}"
}

module "network" {
  source                  = "./modules/network"
  resource_group_location = azurerm_resource_group.public.location
  resource_group_name     = azurerm_resource_group.public.name
  vnet_name               = "vnet-${var.prefix}"
  vms_subnet_name         = "vms-subnet-${var.prefix}"
  vpn_subnet_name         = "GatewaySubnet"
}

module "ubuntu-vm-public-key-auth" {
  source                            = "./modules/ubuntu-vm-public-key-auth"
  ip_configuration_name             = "key-auth-vm-ipconfig-${var.prefix}"
  network_interface_name            = "key-auth-vm-nic-${var.prefix}"
  os_profile_admin_public_key_path  = var.os_profile_admin_public_key_path
  os_profile_admin_username         = var.os_profile_admin_username
  os_profile_computer_name          = "key-auth-vm-${var.prefix}"
  resource_group_location           = azurerm_resource_group.public.location
  resource_group_name               = azurerm_resource_group.public.name
  storage_image_reference_offer     = var.storage_image_reference_offer
  storage_image_reference_publisher = var.storage_image_reference_publisher
  storage_image_reference_sku       = var.storage_image_reference_sku
  storage_image_reference_version   = var.storage_image_reference_version
  storage_os_disk_caching           = var.storage_os_disk_caching
  storage_os_disk_create_option     = var.storage_os_disk_create_option
  storage_os_disk_managed_disk_type = var.storage_os_disk_managed_disk_type
  storage_os_disk_name              = "key-auth-vm-osdisk-${var.prefix}"
  subnet_name                       = module.network.vms_subnet_name
  vm_name                           = "key-auth-vm-${var.prefix}"
  vm_size                           = var.vm_size
  vnet_name                         = module.network.vnet_name
  subnet_id                         = module.network.vms_subnet_id
  nsg_name                          = "key-auth-vm-nsg-${var.prefix}"

  depends_on = [
    azurerm_resource_group.public,
    module.network.vms_subnet_name,
    module.network.vnet_name,
    module.network.vms_subnet_id
  ]
}

module "ubuntu-vm-password-auth" {
  source                            = "./modules/ubuntu-vm-password-auth"
  ip_configuration_name             = "pass-auth-vm-ipconfig-${var.prefix}"
  network_interface_name            = "pass-auth-vm-nic-${var.prefix}"
  os_profile_admin_password         = var.os_profile_admin_password
  os_profile_admin_username         = var.os_profile_admin_username
  os_profile_computer_name          = "pass-auth-vm-${var.prefix}"
  resource_group_location           = azurerm_resource_group.public.location
  resource_group_name               = azurerm_resource_group.public.name
  storage_image_reference_offer     = var.storage_image_reference_offer
  storage_image_reference_publisher = var.storage_image_reference_publisher
  storage_image_reference_sku       = var.storage_image_reference_sku
  storage_image_reference_version   = var.storage_image_reference_version
  storage_os_disk_caching           = var.storage_os_disk_caching
  storage_os_disk_create_option     = var.storage_os_disk_create_option
  storage_os_disk_managed_disk_type = var.storage_os_disk_managed_disk_type
  storage_os_disk_name              = "pass-auth-vm-osdisk-${var.prefix}"
  subnet_name                       = module.network.vms_subnet_name
  vm_name                           = "pass-auth-vm-${var.prefix}"
  vm_size                           = var.vm_size
  vnet_name                         = module.network.vnet_name
  subnet_id                         = module.network.vms_subnet_id
  nsg_name                          = "pass-auth-vm-nsg-${var.prefix}"

  depends_on = [
    azurerm_resource_group.public,
    module.network.vms_subnet_name,
    module.network.vnet_name,
    module.network.vms_subnet_id
  ]
}

module "storage" {
  source                      = "./modules/storage"
  storage_account_name        = "storlinuxvm${var.prefix}"
  storage_account_replication = var.storage_account_replication
  storage_account_tier        = var.storage_account_tier
  storage_container_name      = "contvmlinux${var.prefix}"
  storage_location            = azurerm_resource_group.public.location
  storage_resource_group_name = azurerm_resource_group.public.name

  depends_on = [
    azurerm_resource_group.public
  ]
}

module "keyvault" {
  source                 = "./modules/keyvault"
  kv_location            = azurerm_resource_group.public.location
  kv_name                = "kv-linuxvm-${var.prefix}"
  kv_resource_group_name = azurerm_resource_group.public.name
  object_id              = data.azurerm_client_config.current.object_id
  tenant_id              = data.azurerm_client_config.current.tenant_id

  depends_on = [
    azurerm_resource_group.public
  ]
}

module "keyvault_secrets" {
  source                         = "./modules/keyvault-secrets"
  keyvault_id                    = module.keyvault.id
  storage_access_url             = module.storage.storage_access_url
  storage_account_name           = module.storage.storage_account_name
  storage_connection_string      = module.storage.storage_connection_string
  storage_container_name         = module.storage.storage_container_name
  storage_primary_key            = module.storage.storage_primary_key
  vpn_root_certificate_file_path = "Ps2VPN-RootCert.crt"

  depends_on = [
    module.keyvault,
    module.storage
  ]
}

data "azurerm_key_vault_secret" "vpn-root-certificate" {
  name         = "Ps2VPN-RootCert"
  key_vault_id = module.keyvault.id

  depends_on = [
    module.keyvault.id,
    module.keyvault_secrets
  ]
}

resource "azurerm_public_ip" "vpn_gw_public_ip" {
  name                = "vpn-gw-public-ip-${var.prefix}"
  location            = azurerm_resource_group.public.location
  resource_group_name = azurerm_resource_group.public.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vpn_gw" {
  name                = "vpn-gw-${var.prefix}"
  location            = azurerm_resource_group.public.location
  resource_group_name = azurerm_resource_group.public.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "Basic"

  ip_configuration {
    name                          = "vpn-gw-ipconfig-${var.prefix}"
    public_ip_address_id          = azurerm_public_ip.vpn_gw_public_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.network.vpn_subnet_id
  }

  vpn_client_configuration {
    address_space = ["172.17.0.0/24"]

    root_certificate {
      name             = "VPNROOT"
      public_cert_data = data.azurerm_key_vault_secret.vpn-root-certificate.value
    }
  }
}
