output "bootnode-ip" {
  value = "${azurerm_public_ip.nodeIp.ip_address}"
}
