output "bootnode-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.bootnode.ips}"
}

output "bootnode-tags" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.bootnode.tags}"
}

output "explorer-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.explorer.ips}"
}

output "explorer-tags" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.explorer.tags}"
}

output "moc-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.moc.ips}"
}

output "moc-tags" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.moc.tags}"
}

output "netstat-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.netstat.ips}"
}

output "netstat-tags" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.netstat.tags}"
}

output "validator-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.validator.ips}"
}

output "validator-tags" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.validator.tags}"
}
