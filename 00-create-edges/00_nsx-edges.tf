################################################################
# Provided as-is, NO VMware official support.
#
# Maintainer:   Vladimir Klyubin
# Org:          VMware by Broadcom - VCF - Telco PSO
# e-mail:       vladimir.klyubin@broadcom.com
################################################################

terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
    }
    vsphere = {
      source = "vmware/vsphere"
    }
  }
}

provider "nsxt" {
  host                  = var.nsxt
  username              = var.username
  password              = var.password
  allow_unverified_ssl  = true
}

variable "nsxt" {
  type = string
}
variable "username" {
  type = string
}
variable "password" {
    type = string
    sensitive = true
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_fqdn
  allow_unverified_ssl  = true
  api_timeout          = 10
}

variable "vsphere_user" {
  type = string
}
variable "vsphere_password" {
  type = string
  sensitive = true
}
variable "vsphere_fqdn" {
  type = string
}

#### Variables

variable compute_manager_name_registered_in_nsx { type = string }
variable allow_ssh_root_login   { type = string }
variable enable_ssh             { type = string }
variable management_network     { type = string }
variable prefix                 { type = string }
variable default_gateways       { type = list }
variable dns                    { type = list }
variable ntp                    { type = list }
variable dns_suffix             { type = string }
variable search_domains         { type = list }
variable node_user_settings     { type = map }
variable host_switches          { type = map }
variable pnics                  { type = map }
variable vsphere_settings       { type = map }
variable edge_nodes             { type = map }
variable edges_advanced_config  { type = list }
variable transport_zones        { type = list }


locals {
  edges_adv_list = { for edge_key, edge_value in var.edge_nodes : edge_key =>  {
        edge_adv    = ( lower(edge_value.advanced_config) == "true" ? var.edges_advanced_config : [] )
    }
  }
}

# NSX ------------------------
data "nsxt_policy_ip_pool" "edges_ip_pool" {
  display_name = var.host_switches.tep_edge_ippool
}

data "nsxt_policy_transport_zone" "tz" {
  for_each = toset(var.transport_zones)
  display_name = each.key
}

data "nsxt_policy_uplink_host_switch_profile" "uplink_host_switch_profile" {
  display_name = var.host_switches.uplink_host_switch_profile
}

data "nsxt_compute_manager" "vcenter" {
  display_name = var.compute_manager_name_registered_in_nsx
}

# vSPHERE ---------------------
data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_settings.datacenter
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_settings.cluster_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  for_each = toset([
    for s in [var.vsphere_settings.reservationpool_name] : s
    if s != ""
  ])
  name = each.value
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

locals {
  nsx_resourcepool_or_cluster_id = var.vsphere_settings.reservationpool_name == "" ? data.vsphere_compute_cluster.compute_cluster.id : data.vsphere_resource_pool.pool[var.vsphere_settings.reservationpool_name].id
}

data "vsphere_folder" "vm_folder" {
  path = length(var.vsphere_settings.folder_name)>0 && var.vsphere_settings.folder_name != null ? var.vsphere_settings.folder_name : "/"
}

data "vsphere_network" "mgmt_network" {
  name = var.management_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "data_networks" {
  for_each = var.pnics
  name = each.value.data_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

locals {
  data_networks_ids = flatten([
    for value in data.vsphere_network.data_networks: value.id
  ])
}

data "vsphere_datastore" "datastore" {
  for_each      = var.edge_nodes
  name          = each.value.datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  for_each      = var.edge_nodes
  name          = each.value.esxi
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "nsxt_edge_transport_node" "edge" {
  for_each      = var.edge_nodes
  description   = each.value.description
  display_name  = each.key

  standard_host_switch {

    host_switch_name = var.host_switches.host_switch_name
    # host_switch_profile = [data.nsxt_policy_uplink_host_switch_profile.uplink_host_switch_profile.realized_id]
    uplink_profile = data.nsxt_policy_uplink_host_switch_profile.uplink_host_switch_profile.realized_id

    ip_assignment {
      static_ip_pool = data.nsxt_policy_ip_pool.edges_ip_pool.realized_id
    }

    dynamic "transport_zone_endpoint" {
      for_each        = toset(var.transport_zones)
      content {
        transport_zone  = data.nsxt_policy_transport_zone.tz[transport_zone_endpoint.key].realized_id
      }
    }

    dynamic "pnic" {
      for_each = var.pnics
      content {
        device_name = pnic.value.device_name
        uplink_name = pnic.value.uplink_name
      }
    }

  }

  deployment_config {
    form_factor = each.value.form_factor

    node_user_settings {
      cli_username  = "admin"
      cli_password  = var.node_user_settings.admin_password
      audit_username = "audit"
      audit_password = var.node_user_settings.audit_password
      root_password = var.node_user_settings.root_password
    }
    vm_deployment_config {
      management_network_id   = data.vsphere_network.mgmt_network.id
      data_network_ids        = local.data_networks_ids
      compute_id              = local.nsx_resourcepool_or_cluster_id
      storage_id              = data.vsphere_datastore.datastore[each.key].id
      vc_id                   = data.nsxt_compute_manager.vcenter.id
      host_id                 = (each.value.esxi !="" && each.value.esxi != null) ? data.vsphere_host.host[each.key].id : null
      compute_folder_id       = (var.vsphere_settings.folder_name != "" && var.vsphere_settings.folder_name != null) ? data.vsphere_folder.vm_folder.id : null
      default_gateway_address = var.default_gateways

      management_port_subnet {
        ip_addresses  = each.value.ips
        prefix_length = var.prefix
      }

      reservation_info {
        cpu_reservation_in_mhz        = each.value.advanced_config ? each.value.cpu_reservation_in_mhz : null
        cpu_reservation_in_shares     = each.value.advanced_config ? each.value.cpu_reservation_in_shares : null
        memory_reservation_percentage = each.value.advanced_config ? each.value.memory_reservation_percentage : null
      }
    }

  }
  node_settings {
    hostname              = "${each.key}.${var.dns_suffix}"
    search_domains        = var.search_domains
    ntp_servers           = var.ntp
    dns_servers           = var.dns
    allow_ssh_root_login  = false
    enable_ssh            = true

    dynamic "advanced_configuration" {
      for_each = each.value.advanced_config ? local.edges_adv_list[each.key].edge_adv : []
      content {
        key   = advanced_configuration.value.param_key
        value = advanced_configuration.value.param_value
      }
    }
  }
  lifecycle {
    ignore_changes = all
  }
}