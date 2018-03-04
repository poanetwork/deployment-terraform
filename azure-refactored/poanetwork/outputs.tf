output "validator-ip" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.validator.ip}"
}
