################################################################
# Provided as-is, NO VMware official support.
#
# Maintainer:     Vladimir Klyubin
# Org:            VMware by Broadcom - VCF - Telco PSO
# e-mail:         vladimir.klyubin@broadcom.com
################################################################

edge_node_clusters = {
  "xgr-enc-comp-b00" = { name = "xgr-enc-comp-b00", cluster_profile = "ec-profile-01", description = "XGR Block 00", edge_nodes = ["ukxgrvnc02111-nvi","ukxgrvnc02112-nvi","ukxgrvnc02113-nvi","ukxgrvnc02114-nvi"] }
}

vsphere = {
  datacenter_name = "UKTPHVVC02005-nvi"
  cluster_name    = "XGR-CAAS-NTWK"
}