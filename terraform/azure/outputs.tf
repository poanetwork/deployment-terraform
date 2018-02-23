output "bootnode-ip" {
  value = "${azurerm_public_ip.nodeIp.ip_address}"
}

output "validator-ip" {
  value = "${azurerm_public_ip.validatorIp.ip_address}"
}
