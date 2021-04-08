# You must run `ssh-keygen -f ~/.ssh/kop_aws` to generate the SSH keys
public_key_path = "~/.ssh/kop_aws.pub"
region          = "cn-north-1"
zone            = "cn-north-1a"

# Ubuntu Server 18.04 LTS (HVM), 64 bits (x86)
ami = "ami-05248307900d52e3a"

instance_types = {
  # 16 vCPU, 122 GiB memory, 2 * 1900 GB (SSD), Network Bandwidth: up to 10 Gb
  "broker" = "i3.4xlarge"
  # 1 vCPU, 2 GiB memory, EBS, Network Bandwidth: low ~ middle
  "zookeeper" = "t2.small"
  # 8 vCPU, 16 GiB memory, EBS, Network Bandwidth: up to 10 Gb
  "client" = "c5a.2xlarge"
  # 2 vCPU, 8 GiB memory, EBS, Network Bandwidth: low ~ middle
  "prometheus" = "t2.large"
}

num_instances = {
  "client"     = 4
  "broker"     = 3
  "zookeeper"  = 3
  "prometheus" = 1
}
