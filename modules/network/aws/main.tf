terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
    region = var.region
}

# Create VPC
resource "aws_vpc" "this" {
    cidr_block          = var.vpc_cidr
    enable_dns_support  = true
    enable_dns_hostnames = true
    tags = {Name = "mc-dev-vpc"}
}

# Create public subnets
resource "aws_subnet" "public"{
    count = length(var.public_subnets)
    vpc_id = aws_vpc.this.id
    cidr_block = var.public_subnets[count.index]
    map_public_ip_on_launch = true
    tags = {Name = "mc-public-${count.index + 1}"}
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.this.id
    tags = {Name = "mc-dev-igw"}
}

# Route Table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id

    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    
    tags = {Name = "mc-public-rt"}
}

# Associate public subnets with route table
resource "aws_route_table_association" "public_assoc" {
    count = length(var.public_subnets)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}


