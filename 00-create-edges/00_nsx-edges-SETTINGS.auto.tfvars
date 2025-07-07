# export TF_VAR_nsxt="nsxt.vmware.com"
# export TF_VAR_username="admin"
# export TF_VAR_password="VMware1!VMware1!"

# export TF_VAR_vsphere_fqdn="vcsa.vmware.com"
# export TF_VAR_vsphere_user="admininstrator@vsphere.local"
# export TF_VAR_vsphere_password="VMware1!VMware1!"

compute_manager_name_registered_in_nsx = "tps-vcsa-01.bus.broadcom.net"

allow_ssh_root_login  = false
enable_ssh            = true
management_network    = "tps-dvpg-mgmt-vm"
prefix                = "26"
default_gateways      = ["10.209.155.129"]
dns                   = ["192.19.189.20","192.19.189.30"]
ntp                   = ["10.10.247.51","10.97.0.60"]
dns_suffix            = "bus.example.com"
search_domains        = ["bus.example.com"]
node_user_settings = {
  admin_password      = "VMware1!VMware1!"
  audit_password      = "VMware1!VMware1!"
  root_password       = "VMware1!VMware1!"
}

host_switches = {
  host_switch_name            = "EdgeHostSwtch"         # Default "nsxHostSwitch"
  uplink_host_switch_profile  = "tps-edge-uplink-profile-01"
  tep_edge_ippool             = "tps-edge-tep"
}
transport_zones               = ["tps-edge-vlan-tz", "tps-overlay-tz"]

pnics = {
  "vmnic1" = { device_name = "fp-eth0", uplink_name = "Uplink-1", data_network = "TPS-SEG-M-3129-TEP-EDGE" }
  "vmnic2" = { device_name = "fp-eth1", uplink_name = "Uplink-2", data_network = "TPS-SEG-M-3129-TEP-EDGE" }
}

vsphere_settings = {
  datacenter            = "tps-datacenter-01"
  reservationpool_name  = "vklyubin"     # Leave it empty if not requirement to put Edges into dedicated pool
  cluster_name          = "tps-cluster-01"
  folder_name           = "vklyubin"     # Leave it empty if not required "tps-fd-mgmt"
}

edges_advanced_config = [
  { param_key = "ovf-param:nsx_edge_tx_ring_size", param_value = 4096 },
  { param_key = "ovf-param:nsx_edge_rx_ring_size", param_value = 4096 },
  { param_key = "advanced-config:sched.cpu.latencySensitivity", param_value = "High" }
]

edge_nodes = {
  "edge1" = { form_factor="SMALL", ips= ["10.209.155.154"], description = "Edge 1", esxi = "sof6-hs1-b0217.bus.broadcom.net", datastore = "tps-cluster-01-vsanDS",
  advanced_config = "false", cpu_reservation_in_mhz = 43104, cpu_reservation_in_shares = "HIGH_PRIORITY", memory_reservation_percentage = 100 }
  "edge2" = { form_factor="SMALL", ips= ["10.209.155.155"], description = "Edge 1", esxi = "sof6-hs1-b0217.bus.broadcom.net", datastore = "tps-cluster-01-vsanDS",
  advanced_config = "false", cpu_reservation_in_mhz = 43104, cpu_reservation_in_shares = "HIGH_PRIORITY", memory_reservation_percentage = 100 }
}