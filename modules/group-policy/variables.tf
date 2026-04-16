variable "groups" {
  description = "NetBird groups with peers and optional policies"
  type = map(object({
    peers = optional(list(string))
    manage_peers = optional(bool)

    policies = optional(map(object({
      protocol       = string
      allowed_groups = list(string)
      ports          = optional(list(number))
    })))
  }))
}
