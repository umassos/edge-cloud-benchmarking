provider "aws" {
  region = "ca-central-1"
}

variable "availability_zone" {
  type = string
  default = "ca-central-1a"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "edge-modeling-vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_security_group" "edge-modeling-security-group" {
  vpc_id = aws_vpc.edge-modeling-vpc.id

  # allow ssh
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow all intra-vpc traffic
  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [aws_vpc.edge-modeling-vpc.cidr_block]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_internet_gateway" "edge-modeling-gateway" {
  vpc_id = aws_vpc.edge-modeling-vpc.id

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_subnet" "edge-modeling-public-subnet" {
  vpc_id = aws_vpc.edge-modeling-vpc.id
  cidr_block = "172.16.10.0/24"
  availability_zone = var.availability_zone

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table" "edge-modeling-route-table" {
  vpc_id = aws_vpc.edge-modeling-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.edge-modeling-gateway.id
  }

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table_association" "public-route-table-association" {
  route_table_id = aws_route_table.edge-modeling-route-table.id
  subnet_id = aws_subnet.edge-modeling-public-subnet.id
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_subnet" "edge-modeling-private-subnet" {
  vpc_id = aws_vpc.edge-modeling-vpc.id
  cidr_block = "172.16.20.0/24"
  availability_zone = var.availability_zone

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.edge-modeling-public-subnet.id
  depends_on = [aws_internet_gateway.edge-modeling-gateway]

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.edge-modeling-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table_association" "private-route-table-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id = aws_subnet.edge-modeling-private-subnet.id
}

resource "aws_key_pair" "edge-modeling-key-pair" {
  key_name = "edge-modeling"
  public_key = file("edge-modeling.pub")
}

resource "aws_instance" "master" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.small"
  # ToDo: change the instance type

  key_name = aws_key_pair.edge-modeling-key-pair.id
  subnet_id = aws_subnet.edge-modeling-public-subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.edge-modeling-security-group.id]
}

resource "aws_instance" "workers" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.small"
  # ToDo: change the instance type
  count = 2

  key_name = aws_key_pair.edge-modeling-key-pair.id
  subnet_id = aws_subnet.edge-modeling-private-subnet.id
  vpc_security_group_ids = [aws_security_group.edge-modeling-security-group.id]
}

resource "local_file" "ansible-hosts" {
  content = templatefile("ansible/inventory/hosts.tpl",{
    master-public-ip = aws_instance.master.public_ip,
    master-private-ip = aws_instance.master.private_ip,
    worker-private-ip = aws_instance.workers.*.private_ip
  })
  filename = "ansible/inventory/hosts.ini"
  file_permission = "0644"
}

output "load-balancer-id" {
  value = aws_instance.master.id
}

output "load-balancer-ip" {
  value = aws_instance.master.public_ip
}

output "workers-id" {
  value = aws_instance.workers.*.id
}
