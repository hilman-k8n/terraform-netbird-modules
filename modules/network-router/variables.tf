variable "networks" {
  description = "Map of router configurations containing namespaces, CIDRs, and hosts definitions."
  type = map(object({
    routing_peers = optional(object({
      create_group = bool
      peers        = optional(list(string))
    }), {
      create_group = false
      peers        = []
    })
    resources = object({
      namespaces = optional(list(object({
        name           = string
        allowed_groups = list(string)
      })), [])
      cidrs = optional(list(object({
        name           = string
        cidr           = optional(string)
        allowed_groups = list(string)
        protocol          = optional(string)
        ports           = optional(list(string))
      })), [])
      hosts = optional(list(object({
        name           = string
        host           = optional(string)
        allowed_groups = list(string)
        protocol          = optional(string)
        ports           = optional(list(string))
      })), [])
    })
  }))
}

variable "bypass_dns" {
    description = "Override DNS for all CIDR network resource (default: nat, all)"
    type = object({
        enabled = optional(bool)
        name = optional(string)
        nameservers = optional(list(string))
        groups = optional(list(string))
    })
    default = {
        enabled = false
        name = "bypass-dns"
        nameservers = ["9.9.9.9", "1.1.1.1", "8.8.8.8"]
        groups = ["all", "nat"]
    }
}

variable "enable_resource_name_suffix" {
    default     = true
    type        = bool
    description = "Enable/disable network resource naming suffix"
}

variable "k8s_resource_prefix" {
    default     = "k8s"
    type        = string
    description = "Network resource naming prefix for kubernetes namespace."
}

variable "cidr_resource_prefix" {
    default     = "cidr"
    type        = string
    description = "Network resource naming prefix for CIDR."
}


variable "hosts_resource_prefix" {
    default     = "host"
    type        = string
    description = "Network resource naming prefix for host."
}