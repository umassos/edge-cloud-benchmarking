provider "aws" {
  alias = "cluster"
  region = "ca-central-1"
}

variable "cluster-az" {
  type = string
  default = "ca-central-1a"
}

variable "worker-count" {
  type = number
  default = 5
}

data "aws_ami" "cluster-ami" {
  provider = aws.cluster
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

resource "aws_vpc" "cluster-vpc" {
  provider = aws.cluster
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_security_group" "cluster-sg" {
  provider = aws.cluster
  vpc_id = aws_vpc.cluster-vpc.id

  # allow ssh
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow http
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow ping
  ingress {
    protocol = "icmp"
    from_port = 8
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow all intra-vpc traffic
  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [aws_vpc.cluster-vpc.cidr_block]
  }

  # allow all outgoing traffic
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

resource "aws_subnet" "cluster-public-subnet" {
  provider = aws.cluster
  vpc_id = aws_vpc.cluster-vpc.id
  cidr_block = "172.16.10.0/24"
  availability_zone = var.cluster-az

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_internet_gateway" "cluster-igw" {
  provider = aws.cluster
  vpc_id = aws_vpc.cluster-vpc.id

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table" "cluster-public-rt" {
  provider = aws.cluster
  vpc_id = aws_vpc.cluster-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster-igw.id
  }

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table_association" "cluster-public-rt-association" {
  provider = aws.cluster
  route_table_id = aws_route_table.cluster-public-rt.id
  subnet_id = aws_subnet.cluster-public-subnet.id
}

resource "aws_eip" "cluster-nat-eip" {
  provider = aws.cluster
  vpc = true

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_subnet" "cluster-private-subnet" {
  provider = aws.cluster
  vpc_id = aws_vpc.cluster-vpc.id
  cidr_block = "172.16.20.0/24"
  availability_zone = var.cluster-az

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_nat_gateway" "cluster-nat-gw" {
  provider = aws.cluster
  allocation_id = aws_eip.cluster-nat-eip.id
  subnet_id = aws_subnet.cluster-public-subnet.id
  depends_on = [aws_internet_gateway.cluster-igw]

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table" "cluster-nat-rt" {
  provider = aws.cluster
  vpc_id = aws_vpc.cluster-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cluster-nat-gw.id
  }

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table_association" "private-route-table-association" {
  provider = aws.cluster
  route_table_id = aws_route_table.cluster-nat-rt.id
  subnet_id = aws_subnet.cluster-private-subnet.id
}

resource "aws_key_pair" "cluster-key-pair" {
  provider = aws.cluster
  key_name = "edge-modeling-cluster"
  public_key = file("edge-modeling.pub")

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_instance" "master" {
  provider = aws.cluster
  ami = data.aws_ami.cluster-ami.id
  instance_type = "c5n.2xlarge"

  key_name = aws_key_pair.cluster-key-pair.id
  subnet_id = aws_subnet.cluster-public-subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.cluster-sg.id]
}

resource "aws_instance" "workers" {
  provider = aws.cluster
  ami = data.aws_ami.cluster-ami.id
  instance_type = "c5a.xlarge"
  count = var.worker-count

  key_name = aws_key_pair.cluster-key-pair.id
  subnet_id = aws_subnet.cluster-private-subnet.id
  vpc_security_group_ids = [aws_security_group.cluster-sg.id]
}
