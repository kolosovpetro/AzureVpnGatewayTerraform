output "ssh_private_ip" {
  value = module.ubuntu-vm-public-key-auth.private_ip
}

output "pass_private_ip" {
  value = module.ubuntu-vm-password-auth.private_ip
}
