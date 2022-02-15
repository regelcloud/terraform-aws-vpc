provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block                       = var.cidr_block
  instance_tenancy                 = var.instance_tenancy
  enable_dns_support               = var.enable_dns_support
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_classiclink               = var.enable_classiclink
  enable_classiclink_dns_support   = var.enable_classiclink_dns_support
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = {
    Name        = "${var.Tags.Name}-${var.Tags.Environment}-vpc"
    Application = var.Tags.Application
    Environment = var.Tags.Environment
    Tier        = var.Tags.Tier
    Criticality = var.Tags.Criticality
    Requestor   = var.Tags.Requestor
    Support     = var.Tags.Support
    Client      = var.Tags.Client
    CostCenter  = var.Tags.CostCenter
  }
}



# e.g. Create subnets in the all available availability zones

locals {
  subnetworks-count = "${length(data.aws_availability_zones.available.names)}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "main" {
  count             = local.subnetworks-count
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${cidrsubnet(var.private_subnet_base_cidr, var.private_subnet_cidr_split, count.index)}"
  ## Example for cidrsubnet 
  ## base_subnet cidr is 10.0.0.0/16
  ##  and diff is 8 then 
  ## first subnet will be 10.0.1.0/24 and 
  ## second will be 10.0.2.0/24
  ## same goes for all availablity zone count
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name        = "private-subnet-${var.Tags.Name}-${var.Tags.Environment}-${data.aws_availability_zones.available.names[count.index]}"
    Application = var.Tags.Application
    Environment = var.Tags.Environment
    Tier        = var.Tags.Tier
    Criticality = var.Tags.Criticality
    Requestor   = var.Tags.Requestor
    Support     = var.Tags.Support
    Client      = var.Tags.Client
    CostCenter  = var.Tags.CostCenter
  }

}

resource "aws_subnet" "public" {
  count             = 2
  # count             = local.subnetworks-count
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${cidrsubnet(var.public_subnet_base_cidr, var.public_subnet_cidr_split, count.index)}"
  ## Example for cidrsubnet 
  ## base_subnet cidr is 10.0.0.0/16
  ##  and diff is 8 then 
  ## first subnet will be 10.0.1.0/24 and 
  ## second will be 10.0.2.0/24
  ## same goes for all availablity zone count
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name        = "public-subnet-${var.Tags.Name}-${var.Tags.Environment}-${data.aws_availability_zones.available.names[count.index]}"
    Application = var.Tags.Application
    Environment = var.Tags.Environment
    Tier        = var.Tags.Tier
    Criticality = var.Tags.Criticality
    Requestor   = var.Tags.Requestor
    Support     = var.Tags.Support
    Client      = var.Tags.Client
    CostCenter  = var.Tags.CostCenter
  }

}


## Igw
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name        = "igw-${var.Tags.Name}-${var.Tags.Environment}"
    Application = var.Tags.Application
    Environment = var.Tags.Environment
    Tier        = var.Tags.Tier
    Criticality = var.Tags.Criticality
    Requestor   = var.Tags.Requestor
    Support     = var.Tags.Support
    Client      = var.Tags.Client
    CostCenter  = var.Tags.CostCenter
  }


}

## Public Route table
resource "aws_route_table" "prt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name        = "public-rt-${var.Tags.Name}-${var.Tags.Environment}"
    Application = var.Tags.Application
    Environment = var.Tags.Environment
    Tier        = var.Tags.Tier
    Criticality = var.Tags.Criticality
    Requestor   = var.Tags.Requestor
    Support     = var.Tags.Support
    Client      = var.Tags.Client
    CostCenter  = var.Tags.CostCenter
  }
  depends_on = ["aws_internet_gateway.igw"]
}

## public subnet rt association
resource "aws_route_table_association" "prta" {
  count          = 2
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.prt.id}"
}

# resource "aws_route" "route" {
#   route_table_id         = "${aws_route_table.prt.id}"
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = "${aws_internet_gateway.igw.id}"
#   depends_on             = ["aws_route_table.prt"]
# }

########################## Private Section #######################
## Private Route table
resource "aws_route_table" "private-rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"
  }

  tags = {
    Name        = "private-rt-${var.Tags.Name}-${var.Tags.Environment}"
    Application = var.Tags.Application
    Environment = var.Tags.Environment
    Tier        = var.Tags.Tier
    Criticality = var.Tags.Criticality
    Requestor   = var.Tags.Requestor
    Support     = var.Tags.Support
    Client      = var.Tags.Client
    CostCenter  = var.Tags.CostCenter
  }
  depends_on = ["aws_nat_gateway.ngw"]
}

## private subnet rt association
resource "aws_route_table_association" "private-rta" {
  count          = local.subnetworks-count
  subnet_id      = "${element(aws_subnet.main.*.id, count.index)}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

# Nat eip

resource "aws_eip" "nat-ip" {
  vpc = true
}


## Nat Gateway 
resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.nat-ip.id}"
  subnet_id     = "${aws_subnet.public.0.id}"

  tags = {
    Name        = "ngw-${var.Tags.Name}-${var.Tags.Environment}"
    Application = var.Tags.Application
    Environment = var.Tags.Environment
    Tier        = var.Tags.Tier
    Criticality = var.Tags.Criticality
    Requestor   = var.Tags.Requestor
    Support     = var.Tags.Support
    Client      = var.Tags.Client
    CostCenter  = var.Tags.CostCenter
  }
  depends_on = ["aws_eip.nat-ip", "aws_subnet.public"]

}

resource "aws_security_group" "allow-internal" {
  name        = "${var.Tags.Client}-allow-internal"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "allow-internal"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [  aws_vpc.main.cidr_block ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.Tags.Client}-allow-internal"
  }
}