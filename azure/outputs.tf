output "bootnode-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.bootnode-ips}"
}

output "explorer-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.explorer-ips}"
}

output "moc-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.moc-ips}"
}

output "netstats-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.netstats-ips}"
}

output "validator-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.validator-ips}"
}
