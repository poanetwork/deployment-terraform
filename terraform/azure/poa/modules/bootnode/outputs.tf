# The IP address running netstat
output "ip" {
  value = "${azurerm_public_ip.bootnode.ip_address}"
}
