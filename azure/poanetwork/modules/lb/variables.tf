variable region {
  description = "The region where to create resources"
  default     = "West US 2"
}

variable prefix {
  description = "Prefix allows you to make structured names for the resources"
  default     = "tf-"
}

variable resource_group_name {
  description = "Resource group name. All created resources reside within this resource group"
}

variable lb_node_count {
  description = "How many balanced nodes to deploy (for bootnodes)"
  default     = 0
}

variable environment_name {
  description = "Set the environment tag for all created resources"
  default     = "Terraform Demo"
}

variable role {
  description = "Role of the node"
}

variable opened_ports_by_role {
  description = "What ports should be opened on the node?"
  type        = "map"

  default = {
    "bootnode-lb"  = ["p2p", "p2p-udp", "rpc", "https"]
  }
}

variable ports {
  description = "Ports LB mapping"
  type        = "map"

  default = {
    https = ["443", "Tcp", "443"]
    rpc = ["8545", "Tcp", "8545"]
    p2p = ["30303", "Tcp", "30303"]
    p2p-udp = ["30303", "Udp", "30303"]
    http-3000 = ["3000", "Tcp", "3000"]
  }
}