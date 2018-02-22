output "bootnode-ip" {
  value = "${azurerm_public_ip.nodeIp.ip_address}"
}

output "moc-ip" {
  value = "${azurerm_public_ip.mocIp.ip_address}"
}
