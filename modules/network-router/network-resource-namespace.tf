resource "netbird_group" "namespaces" {
  for_each = merge([
    for router_name, router in var.networks : {
      for ns in try(router.resources.namespaces, []) :
        "${var.k8s_resource_prefix}-${ns.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router    = router_name
          namespace = ns
        }
      if ns.name != "all"
    }
  ]...)

  name = each.key
}


resource "netbird_group" "namespaces_all" {
  for_each = var.networks

  name = "${var.k8s_resource_prefix}-all${var.enable_resource_name_suffix ? "-via-${each.key}" : ""}"
}

resource "netbird_network_resource" "namespaces" {
  for_each = merge([
    for router_name, router in var.networks : {
      for ns in try(router.resources.namespaces, []) :
        "${var.k8s_resource_prefix}-${ns.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router    = router_name
          namespace = ns
        } if ns.name != "all"
    }
  ]...)

  network_id = netbird_network.this[each.value.router].id
  name       = each.key
  address    = "*.${each.value.namespace.name}.svc.cluster.local"
  groups = sort([
    netbird_group.namespaces_all[each.value.router].id,
    netbird_group.namespaces[each.key].id
  ])
}

resource "netbird_policy" "namespaces_all" {
  for_each = merge([
    for router_name, router in var.networks : {
      for ns in try(router.resources.namespaces, []) :
        "${var.k8s_resource_prefix}-${ns.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router    = router_name
          namespace = ns
        } if ns.name == "all" && length(try(ns.allowed_groups, [])) > 0
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
      for group_name in each.value.namespace.allowed_groups :
      contains(keys(var.networks), group_name) ? netbird_group.this[group_name].id : data.netbird_group.external[group_name].id
    ])
    destinations = [netbird_group.namespaces_all[each.value.router].id]
  }
}

resource "netbird_policy" "namespaces" {
  for_each = merge([
    for router_name, router in var.networks : {
      for ns in try(router.resources.namespaces, []) :
        "${var.k8s_resource_prefix}-${ns.name}${var.enable_resource_name_suffix ? "-via-${router_name}" : ""}" => {
          router    = router_name
          namespace = ns
        } if ns.name != "all" && length(try(ns.allowed_groups, [])) > 0
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
      for group_name in each.value.namespace.allowed_groups :
      contains(keys(var.networks), group_name) ? netbird_group.this[group_name].id : data.netbird_group.external[group_name].id
    ])
    destinations = [netbird_group.namespaces[each.key].id]
  }
}