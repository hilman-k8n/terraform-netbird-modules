resource "netbird_group" "cidrs" {
  for_each = merge([
    for router_name, router in var.networks : {
      for cidr in try(router.resources.cidrs, []) :
        "${var.cidr_resource_prefix}-${cidr.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router = router_name
          cidr   = cidr
        }

      if cidr.name != "all"
    }
  ]...)

  name = each.key
}


resource "netbird_group" "cidrs_all" {
  for_each = var.networks

  name = "${var.cidr_resource_prefix}-all${var.enable_resource_name_suffix ? "-via-${each.key}" : ""}"
}


resource "netbird_network_resource" "cidrs" {
  for_each = merge([
    for router_name, router in var.networks : {
      for cidr in try(router.resources.cidrs, []) :
        "${var.cidr_resource_prefix}-${cidr.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router = router_name
          cidr   = cidr
        } if cidr.name != "all" && try(cidr.cidr, null) != null
    }
  ]...)

  network_id = netbird_network.this[each.value.router].id
  name       = each.key
  address    = each.value.cidr.cidr
  groups = sort([
    netbird_group.cidrs_all[each.value.router].id,
    netbird_group.cidrs[each.key].id
  ])
}

resource "netbird_policy" "cidrs_all" {
  for_each = merge([
    for router_name, router in var.networks : {
      for cidr in try(router.resources.cidrs, []) :
        "${var.cidr_resource_prefix}-${cidr.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router = router_name
          cidr   = cidr
        } if cidr.name == "all" && length(try(cidr.allowed_groups, [])) > 0
    }
  ]...)

  name    = "${each.key}"
  enabled = true

  rule {
    name          = "${each.key}-all-rule"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "all"
    sources = sort([
      for group_name in each.value.cidr.allowed_groups :
      contains(keys(var.networks), group_name) ? netbird_group.this[group_name].id : data.netbird_group.external[group_name].id
    ])
    destinations = [netbird_group.cidrs_all[each.value.router].id]
    
  }
}

resource "netbird_policy" "cidrs" {
  for_each = merge([
    for router_name, router in var.networks : {
      for cidr in try(router.resources.cidrs, []) :
        "${var.cidr_resource_prefix}-${cidr.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router = router_name
          cidr   = cidr
        } if cidr.name != "all" && length(try(cidr.allowed_groups, [])) > 0
    }
  ]...)

  name    = each.key
  enabled = true

  rule {
    name          = "${each.key}-rule"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = try(each.value.cidr.protocol, null)
    ports         = try(each.value.cidr.ports, null)
    sources = sort([
      for group_name in each.value.cidr.allowed_groups :
      contains(keys(var.networks), group_name) ? netbird_group.this[group_name].id : data.netbird_group.external[group_name].id
    ])
    destinations = [netbird_group.cidrs[each.key].id]
  }
}