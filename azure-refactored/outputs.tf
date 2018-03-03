output "validator-ip" {
  description = "Public IP address of the validator virtual machine"
  value = "Validator node IP: ${module.poa.validator-ip}"
}
