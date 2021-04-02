provider "aws" {
  alias = "load-generator"
  region = "us-east-2"
}

variable "load-generator-az" {
  type = string
  default = "us-east-2b"
}

data "aws_ami" "load-generator-ami" {
  provider = aws.load-generator
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

resource "aws_vpc" "load-generator-vpc" {
  provider = aws.load-generator
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_security_group" "load-generator-sg" {
  provider = aws.load-generator
  vpc_id = aws_vpc.load-generator-vpc.id

  # allow ssh
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_subnet" "load-generator-subnet" {
  provider = aws.load-generator
  vpc_id = aws_vpc.load-generator-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.load-generator-az

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_internet_gateway" "load-generator-igw" {
  provider = aws.load-generator
  vpc_id = aws_vpc.load-generator-vpc.id

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table" "load-generator-rt" {
  provider = aws.load-generator
  vpc_id = aws_vpc.load-generator-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.load-generator-igw.id
  }

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_route_table_association" "load-generator-rt-association" {
  provider = aws.load-generator
  route_table_id = aws_route_table.load-generator-rt.id
  subnet_id = aws_subnet.load-generator-subnet.id
}


resource "aws_key_pair" "load-generator-key-pair" {
  provider = aws.load-generator
  key_name = "edge-modeling-load-generator"
  public_key = file("edge-modeling.pub")

  tags = {
    name = "edge-modeling"
  }
}

resource "aws_instance" "load_generator" {
  provider = aws.load-generator
  ami = data.aws_ami.load-generator-ami.id
  instance_type = "c5n.2xlarge"

  key_name = aws_key_pair.load-generator-key-pair.id
  subnet_id = "subnet-1a5d4b62" # default subnet for us-east-2b
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
  }
}
