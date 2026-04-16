data "netbird_peer" "this" {
  for_each = toset(flatten([
    for g in values(var.groups) : g.peers

    if coalesce(g.manage_peers, true)
  ]))

  name = each.value
}

resource "netbird_group" "this" {
  for_each = {
    for k, v in var.groups: k => v
    if coalesce(v.manage_peers, true)
  } 

  name = each.key
  peers = sort([
    for name in sort(each.value.peers) :
    data.netbird_peer.this[name].id
  ])
}

resource "netbird_group" "unmanaged" {
  for_each = {
    for k, v in var.groups: k => v
    if !coalesce(v.manage_peers, true)
  } 

  name = each.key
}

resource "netbird_policy" "this" {
  for_each = {
    for item in flatten([
      for group_name, group in var.groups : [
        for policy_name, policy in coalesce(group.policies, {}) : {
          key            = "${group_name}.${policy_name}"
          name           = policy_name
          group          = group_name
          protocol       = policy.protocol
          ports          = try(policy.ports, [])
          allowed_groups = policy.allowed_groups
        }
      ]
    ]) : item.key => item
  }

  name = each.value.name

  rule {
    name          = each.value.name
    bidirectional = false

    sources = sort( [
      for g in each.value.allowed_groups :
      try(netbird_group.this[g].id, netbird_group.unmanaged[g].id)
    ])

    destinations = [
      try(netbird_group.this[each.value.group].id, netbird_group.unmanaged[each.value.group].id)
    ]

    protocol = each.value.protocol
    ports    = each.value.protocol == "all" ? null : each.value.ports
    action   = "accept"
  }
}
