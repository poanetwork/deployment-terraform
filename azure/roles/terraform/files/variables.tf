variable network_name {
  description = "Name of the POA Network"
  default     = "POA"
}

variable bootnode_count {
  description = "A number of bootnodes to create"
  default     = "1"
}

variable bootnode_lb_count {
  description = "A number of balanced bootnodes to create"
  default     = "0"
}

variable validator_count {
  description = "A number of validators to create"
  default     = "1"
}

variable region {
  description = "Region where VMs will be created"
  default     = "East US"
}      

variable resource_group_name {
  description = "Name of the resource group"
  default     = "tf-test-full-setup"
}

variable prefix {
  description = "Prefix all resources names with this string"
  default = "tf-"
}

variable environment_name {
  description = "Name of the environment. VMs will be tagged with this."
  default     = "POA"
}
      
variable ssh_public_key {
  description = "Local storage for public SSH key that will be used to connect to the remote VMs"
  default     = "~/.ssh/id_rsa.pub"
} 

variable admin_username {
  description = "Default user for machine"
  default     = "poa"
}