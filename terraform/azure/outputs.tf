output "bootnode-ip" {
  value = "${azurerm_public_ip.nodeIp.ip_address}"
}

output "netstat-ip" {
  value = "${azurerm_public_ip.netstatIp.ip_address}"
}

output "moc-ip" {
  value = "${azurerm_public_ip.mocIp.ip_address}"
}

output "explorer-ip" {
  value = "${azurerm_public_ip.explorerIp.ip_address}"
}
