# The IP address running netstat
output "netstat_node_ip" {
  value = "${azurerm_public_ip.netstat.ip_address}"
}
