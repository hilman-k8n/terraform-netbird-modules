data "netbird_group" "external" {
  for_each = toset(flatten(concat([
    for router_name, router in var.networks : [
      for ns in try(router.resources.namespaces, []) : [
        for group_name in try(ns.allowed_groups, []) :
        group_name if !contains(keys(var.networks), group_name)
      ]
    ]
  ], [
    for router_name, router in var.networks : [
      for cidr in try(router.resources.cidrs, []) : [
        for group_name in try(cidr.allowed_groups, []) :
        group_name if !contains(keys(var.networks), group_name)
      ]
    ]
  ], [
    for router_name, router in var.networks : [
      for host in try(router.resources.hosts, []) : [
        for group_name in try(host.allowed_groups, []) :
        group_name if !contains(keys(var.networks), group_name)
      ]
    ]
  ])))

  name = each.key
}


data "netbird_group" "this" {
  for_each = {
    for k, v in var.networks : k => v
    if !v.routing_peers.create_group
  }

  name = each.key
}