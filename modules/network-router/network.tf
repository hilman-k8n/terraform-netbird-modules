resource "netbird_group" "this" {
  for_each = {
    for k, v in var.networks : k => v
    if v.routing_peers.create_group
  }

  name = each.key

  peers = sort([
    for p in each.value.routing_peers.peers :
    data.netbird_peer.this[p].id
  ])
}


data "netbird_peer" "this" {
  for_each = toset(flatten([
    for _, n in var.networks :
    n.routing_peers.create_group ? n.routing_peers.peers : []
  ]))

  name = each.key
}

resource "netbird_network" "this" {
  for_each    =  var.networks
  
  name        = each.key
  description = "Managed by terraform"
}

resource "netbird_network_router" "this" {
  for_each = var.networks

  network_id = netbird_network.this[each.key].id

  peer_groups = [
    each.value.routing_peers.create_group
      ? netbird_group.this[each.key].id
      : data.netbird_group.this[each.key].id
  ]

  metric     = 9999
  enabled    = true
  masquerade = true
}
