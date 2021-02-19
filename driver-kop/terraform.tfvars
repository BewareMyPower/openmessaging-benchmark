
location = "eastus"

# TODO: change to Azure instance type, currently this variable is unused.
instance_types = {
  "broker" = "i3en.2xlarge"
}

num_instances = {
  "broker" = 3
}

#instance_types = {
#  "broker"              = "i3en.2xlarge"
#  "zookeeper-pulsar"    = "t2.small"
#  "zookeeper-kafka"     = "t2.small"
#  "client-pulsar"       = "c5n.2xlarge"
#  "client-kafka"        = "c5n.2xlarge"
#  "prometheus-pulsar"   = "t2.large"
#  "prometheus-kafka"    = "t2.large"
#}
#
#num_instances = {
#  "client-pulsar"       = 4
#  "client-kafka"        = 4
#  "broker"              = 3
#  "zookeeper-pulsar"    = 3
#  "zookeeper-kafka"     = 3
#  "prometheus-pulsar"   = 1
#  "prometheus-kafka"    = 1
#}
