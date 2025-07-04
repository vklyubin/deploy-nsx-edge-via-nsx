# Deploy NSX Edge using NSX terraform provider

## 1. Pre-reqs

1. System with access to internet or with locally available vmware/nsxt provider
2. Terraform scripts
3. Updated value files

## 2. Perform deployment

1. Initialize terraform

`terraform init`

2. Deploy NSX edges:

```bash
terraform plan

terraform apply
```