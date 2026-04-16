output "networks" {
  description = "Map of NetBird networks created by this module, keyed by network name."
  value       = netbird_network.this
}

output "network_resource_namespaces" {
  description = "NetBird network resources representing Kubernetes namespaces (*.<namespace>.svc.cluster.local)."
  value       = netbird_network_resource.namespaces
}

output "network_resource_cidrs" {
  description = "NetBird network resources created for CIDR-based routes (excluding 'all')."
  value       = netbird_network_resource.cidrs
}

output "network_resource_hosts" {
  description = "NetBird network resources created for individual host addresses."
  value       = netbird_network_resource.hosts
}

output "policy_namespaces" {
  description = "NetBird policies allowing access to specific Kubernetes namespaces based on allowed groups."
  value       = netbird_policy.namespaces
}

output "policy_namespaces_all" {
  description = "NetBird policies allowing access to all Kubernetes namespaces for a network."
  value       = netbird_policy.namespaces_all
}

output "policy_cidrs" {
  description = "NetBird policies controlling access to specific CIDR resources."
  value       = netbird_policy.cidrs
}

output "policy_cidrs_all" {
  description = "NetBird policies controlling access to all CIDR resources for a network."
  value       = netbird_policy.cidrs_all
}

output "policy_hosts" {
  description = "NetBird policies controlling access to individual host resources."
  value       = netbird_policy.hosts
}

output "policy_hosts_all" {
  description = "NetBird policies controlling access to all host resources for a network."
  value       = netbird_policy.hosts_all
}

output "nameserver_bypass_dns" {
  description = "NetBird nameserver group used for DNS bypass."
  value       = netbird_nameserver_group.bypass_dns
}