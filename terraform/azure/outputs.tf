output "bootnode-ip" {
  value = "${azurerm_public_ip.nodeIp.ip_address}"
}

output "validator-ip" {
  value = "${azurerm_public_ip.validatorIp.ip_address}"
}

output "netstat-ip" {
  value = "${module.netstat.netstat_node_ip}"
}

output "moc-ip" {
  value = "${azurerm_public_ip.mocIp.ip_address}"
}

output "explorer-ip" {
  value = "${azurerm_public_ip.explorerIp.ip_address}"
}
