################################################################
# Provided as-is, NO VMware official support.
#
# Maintainer:     Vladimir Klyubin
# Org:            VMware by Broadcom - VCF - Telco PSO
# e-mail:         vladimir.klyubin@broadcom.com
################################################################

terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
    }
    vsphere = {
      source = "hashicorp/vsphere"
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

# Varibales
variable edge_node_clusters   { type = map }
variable vsphere              { type = map }

data "nsxt_transport_node" "edge_node" {
  for_each      = toset(flatten([ 
    for cluster_name_key, value in var.edge_node_clusters: value.edge_nodes
  ]))
  display_name  = each.key
}

resource "nsxt_edge_cluster" "edge_cluster" {
  for_each      = var.edge_node_clusters
  description   = each.value.description
  display_name  = each.value.name

  dynamic member {
    for_each = toset(each.value.edge_nodes)
    content {
      transport_node_id = data.nsxt_transport_node.edge_node[member.key].id
    }
  }
}

data "vsphere_datacenter" "datacenter" {
  name = var.vsphere.datacenter_name
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere.cluster_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "vm" {
  for_each      = toset(flatten([ 
    for cluster_name_key, value in var.edge_node_clusters: value.edge_nodes
  ]))
  name          = each.key
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# output "vms" {
#   value = data.vsphere_virtual_machine.vm
# }

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "vm_anti_affinity_rule" {
  for_each            = var.edge_node_clusters
  name                = "aaf-${each.value.name}"
  compute_cluster_id  = data.vsphere_compute_cluster.cluster.id
  virtual_machine_ids = [for vm_name in each.value.edge_nodes : data.vsphere_virtual_machine.vm[vm_name].id]

  # lifecycle {
  #   replace_triggered_by = [vsphere_virtual_machine.vm]
  # }
}