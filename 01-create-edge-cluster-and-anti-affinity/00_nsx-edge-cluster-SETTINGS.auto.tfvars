# export TF_VAR_nsxt="nsxt.vmware.com"
# export TF_VAR_username="admin"
# export TF_VAR_password="VMware1!VMware1!"

# export TF_VAR_vsphere_fqdn="vcsa.vmware.com"
# export TF_VAR_vsphere_user="admininstrator@vsphere.local"
# export TF_VAR_vsphere_password="VMware1!VMware1!"

edge_node_clusters = {
  "enc-cluster-vfdemo" = { name = "enc-cluster-vfdemo", cluster_profile = "ec-profile-01", description = "XGR Block 00", edge_nodes = ["edge1","edge2"] }
}

vsphere = {
  datacenter_name = "tps-datacenter-01"
  cluster_name    = "tps-cluster-01"
}