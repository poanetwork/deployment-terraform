output "ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${azurerm_public_ip.node.*.ip_address}"
}

output "tags" {
  description = "All the tags of the VMs"
  value       = "${azurerm_virtual_machine.node.*.tags.countable_role}"
}