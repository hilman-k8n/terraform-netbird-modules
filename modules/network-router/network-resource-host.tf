resource "netbird_group" "hosts" {
  for_each = merge([
    for router_name, router in var.networks : {
      for host in try(router.resources.hosts, []) :
        "${var.hosts_resource_prefix}-${host.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router = router_name
          host   = host
        }
      if host.name != "all"
    }
  ]...)

  name = each.key
}

resource "netbird_group" "hosts_all" {
  for_each = var.networks

  name = "${var.hosts_resource_prefix}-all${var.enable_resource_name_suffix ? "-via-${each.key}" : ""}"
}


resource "netbird_network_resource" "hosts" {
  for_each = merge([
    for router_name, router in var.networks : {
      for host in try(router.resources.hosts, []) :
        "${var.hosts_resource_prefix}-${host.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router = router_name
          host   = host
        }
        if host.name != "all"
    }
  ]...)

  network_id = netbird_network.this[each.value.router].id
  name       = each.key
  address    = each.value.host.host
  groups = sort([
    netbird_group.hosts_all[each.value.router].id,
    netbird_group.hosts[each.key].id
  ])
}

resource "netbird_policy" "hosts" {
  for_each = merge([
    for router_name, router in var.networks : {
      for host in try(router.resources.hosts, []) :
        "${var.hosts_resource_prefix}-${host.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router = router_name
          host   = host
        } if host.name != "all" && length(try(host.allowed_groups, [])) > 0
    }
  ]...)

  name    = each.key
  enabled = true

  rule {
    name          = "${each.key}-rule"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = try(each.value.host.protocol, null)
    ports         = try(each.value.host.ports, null)
    sources = sort([
      for group_name in each.value.host.allowed_groups :
      contains(keys(var.networks), group_name) ? netbird_group.this[group_name].id : data.netbird_group.external[group_name].id
    ])
    destinations = [netbird_group.hosts[each.key].id]
  }
}

resource "netbird_policy" "hosts_all" {
  for_each = merge([
    for router_name, router in var.networks : {
      for host in try(router.resources.hosts, []) :
        "${var.hosts_resource_prefix}-${host.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router = router_name
          host   = host
        } if host.name == "all" && length(try(host.allowed_groups, [])) > 0
    }
  ]...)

  name    = each.key
  enabled = true

  rule {
    name          = "${each.key}-rule"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "all"
    sources = sort([
      for group_name in each.value.host.allowed_groups :
      contains(keys(var.networks), group_name) ? netbird_group.this[group_name].id : data.netbird_group.external[group_name].id
    ])
    destinations = [netbird_group.hosts_all[each.value.router].id]
  }
}