resource_group_name   = "kop-test-rg"
location              = "eastus"
broker_instances      = ["vm-broker-1", "vm-broker-2", "vm-broker-3"]
# 2 vCPU, 8 RAM (GiB), 4 Data disks, IOPS up to 3200, Temporary Storage 16 GiB
broker_vm_size        = "Standard_D2s_v3"
tags = {
  environment = "kop-test"
}
