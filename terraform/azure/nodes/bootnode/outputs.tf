# The IP address running netstat
output "boot_node_ip" {
  value = "${azurerm_public_ip.bootnode.ip_address}"
}
