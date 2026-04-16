
resource "netbird_group" "bypass_dns" {
  count = var.bypass_dns.enabled ? 1 : 0

  name = var.bypass_dns.name
}

resource "netbird_nameserver_group" "bypass_dns" {
  count = var.bypass_dns.enabled ? 1 : 0

  name      = var.bypass_dns.name
  enabled   = true
  nameservers = [
    for ip in var.bypass_dns.nameservers :
    {
      ip = ip
    }
  ]
  
  groups = sort(distinct(flatten([
    for network_name, network in var.networks : [
      for cidr in try(network.resources.cidrs, []) : [
        for group_name in try(cidr.allowed_groups, []) :
        contains(var.bypass_dns.groups, cidr.name) ? data.netbird_group.external[group_name].id : netbird_group.bypass_dns[0].id
      ]
    ]
  ])))
}