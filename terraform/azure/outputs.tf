output "bootnode-ip" {
  value = "${azurerm_public_ip.nodeIp.ip_address}"
}

output "netstat-ip" {
  value = "${azurerm_public_ip.netstatIp.ip_address}"
}
