terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.35.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "random_id" "hash" {
  byte_length = 8
}

variable "key_name" {
  default     = "benchmark-key"
  description = "Desired name prefix for the AWS key pair"
}

# Following variables are loaded from terraform.tfvars
variable "public_key_path" {}
variable "region" {}
variable "zone" {}
variable "ami" {}
variable "instance_types" {}
variable "num_instances" {}

# Create a VPC to launch our instances into
resource "aws_vpc" "benchmark_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Benchmark-VPC-${random_id.hash.hex}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "kafka" {
  vpc_id = aws_vpc.benchmark_vpc.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.benchmark_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.kafka.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "benchmark_subnet" {
  vpc_id                  = aws_vpc.benchmark_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.zone
}

# Get public IP of this machine
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "benchmark_security_group" {
  name   = "terraform-${random_id.hash.hex}"
  vpc_id = aws_vpc.benchmark_vpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All ports open within the VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # All ports open to this machine
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  # Prometheus/Dashboard access
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Benchmark-Security-Group-${random_id.hash.hex}"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}-${random_id.hash.hex}"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "zookeeper" {
  ami                    = var.ami
  instance_type          = var.instance_types["zookeeper"]
  key_name               = aws_key_pair.auth.id
  subnet_id              = aws_subnet.benchmark_subnet.id
  vpc_security_group_ids = [aws_security_group.benchmark_security_group.id]
  count                  = var.num_instances["zookeeper"]
  monitoring             = true

  tags = {
    Name = "zk-${count.index}"
  }
}

resource "aws_instance" "broker" {
  ami                    = var.ami
  instance_type          = var.instance_types["broker"]
  key_name               = aws_key_pair.auth.id
  subnet_id              = aws_subnet.benchmark_subnet.id
  vpc_security_group_ids = [aws_security_group.benchmark_security_group.id]
  count                  = var.num_instances["broker"]
  monitoring             = true

  tags = {
    Name = "broker-${count.index}"
  }
}

resource "aws_instance" "client" {
  ami                    = var.ami
  instance_type          = var.instance_types["client"]
  key_name               = aws_key_pair.auth.id
  subnet_id              = aws_subnet.benchmark_subnet.id
  vpc_security_group_ids = [aws_security_group.benchmark_security_group.id]
  count                  = var.num_instances["client"]
  monitoring             = true

  tags = {
    Name = "benchmark-client-${count.index}"
  }
}

resource "aws_instance" "prometheus" {
  ami                    = var.ami
  instance_type          = var.instance_types["prometheus"]
  key_name               = aws_key_pair.auth.id
  subnet_id              = aws_subnet.benchmark_subnet.id
  vpc_security_group_ids = [aws_security_group.benchmark_security_group.id]
  count                  = var.num_instances["prometheus"]

  tags = {
    Name = "prometheus-${count.index}"
  }
}

output "clients" {
  value = {
    for instance in aws_instance.client :
    instance.public_ip => instance.private_ip
  }
}

output "brokers" {
  value = {
    for instance in aws_instance.broker :
    instance.public_ip => instance.private_ip
  }
}

output "zookeeper" {
  value = {
    for instance in aws_instance.zookeeper :
    instance.public_ip => instance.private_ip
  }
}

output "prometheus" {
  value = aws_instance.prometheus.0.public_ip
}

output "client_ssh_host" {
  value = "${aws_instance.client.0.public_ip}"
}
