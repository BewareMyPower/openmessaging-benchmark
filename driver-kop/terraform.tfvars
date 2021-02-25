resource_group_name = "kop-test-rg"
location            = "eastus"
admin_user          = "azureuser"

# 8 vCPU, 32 RAM (GiB), 8 Data disks, IOPS up to 12800, Temporary Storage 64 GiB
broker_vm_size   = "Standard_D8s_v3"
broker_instances = ["vm-broker-1", "vm-broker-2", "vm-broker-3"]

# 1 vCPU, 2 RAM (GiB), 2 Data disks, IOPS up to 640, Temporary Storage 4 GiB
zookeeper_vm_size   = "Standard_B1ms"
zookeeper_instances = ["vm-zookeeper-1", "vm-zookeeper-2", "vm-zookeeper-3"]

# 4 vCPU, 14 RAM (GiB), 8 Data disks, IOPS up to 12800, Temporary Storage 28 GiB
client_vm_size   = "Standard_DS3_v2"
client_instances = ["vm-client-1", "vm-client-2", "vm-client-3", "vm-client-4"]

# 2 vCPU, 8 RAM (GiB), 4 Data disks, IOPS up to 3200, Temporary Storage 16 GiB
prometheus_vm_size   = "Standard_D2s_v3"
prometheus_instances = ["vm-prometheus"]

tags = {
  environment = "kop-test"
}
