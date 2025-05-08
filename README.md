# Azure VPN Gateway Terraform

This repository provisions an Azure-based VPN gateway infrastructure using Terraform.
It includes the necessary networking, virtual machines, and VPN configuration for secure access.

## Overview

The infrastructure setup includes:
- Resource group and virtual network creation
- Subnet definitions for virtual machines and VPN gateway
- Deployment of two Linux virtual machines using SSH key authentication
- Azure Key Vault for secure storage of VPN root certificate
- VPN Gateway configuration for client access

## Requirements

- Terraform
- Azure CLI
- SSH key pair
- PowerShell (for root certificate generation)

## Usage

1. Clone the repository
2. Generate a VPN root certificate using the provided PowerShell script
3. Apply the Terraform configuration

## Notes

- Ensure the `id_rsa.pub` file is present in the root directory for VM SSH access
