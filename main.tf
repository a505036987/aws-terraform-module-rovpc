# Creating VPC
resource "aws_vpc" "wssdev-vpc" {
  cidr_block       = var.wssdev-vpc
  instance_tenancy = "default"
  tags = {
    Name = "WSS-Dev"
  }
}

# Creating public subnets
resource "aws_subnet" "publicsub" {
  count             = var.public_sn_count
  vpc_id            = aws_vpc.wssdev-vpc.id
  cidr_block        = "10.158.${80 + count.index}.0/24"
  availability_zone = element(["eu-central-1a", "eu-central-1c", "eu-central-1a"], count.index)
  tags = {
    Name = "WSS Public Subnet${count.index + 1}"
  }
}

# Creating private subnets
resource "aws_subnet" "privatesub" {
  count             = var.private_sn_count
  vpc_id            = aws_vpc.wssdev-vpc.id
  cidr_block        = "10.158.${84 + count.index}.0/24"
  availability_zone = element(["eu-central-1a", "eu-central-1c", "eu-central-1a"], count.index)
  tags = {
    Name = "WSS Private Subnet${count.index + 1}"
  }
}

# Creating workspace subnets
resource "aws_subnet" "workspacesub" {
  count             = var.workspace_sn_count
  vpc_id            = aws_vpc.wssdev-vpc.id
  cidr_block        = "10.158.${88 + count.index}.0/24"
  availability_zone = element(["eu-central-1a", "eu-central-1c", "eu-central-1a"], count.index)
  tags = {
    Name = "WSS Workspace Subnet${count.index + 1}"
  }
}

# Creating a NAT Gateway in each public subnet
resource "aws_eip" "nat_eip" {
  count = length(aws_subnet.publicsub)
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  count = length(aws_subnet.publicsub)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.publicsub.*.id[count.index]
  tags = {
    Name = "WSS NAT Gateway ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "wssdev-gateway" {

  vpc_id = aws_vpc.wssdev-vpc.id
}


# Creating route tables
resource "aws_route_table" "rt_private" {
  count = length(aws_subnet.privatesub)
  vpc_id = aws_vpc.wssdev-vpc.id
  tags = {
    Name = "Private Subnet Route Table_${count.index + 1}"
  }
}


resource "aws_route_table_association" "rt_associate_private" {
  count = var.private_sn_count
  subnet_id      = aws_subnet.privatesub.*.id[count.index]
  route_table_id = aws_route_table.rt_private.*.id[count.index]
}

resource "aws_route_table" "rt_public" {
  depends_on = [
    aws_internet_gateway.wssdev-gateway
  ]
  vpc_id = aws_vpc.wssdev-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wssdev-gateway.id
  }
  tags = {
    Name = "Public Subnet Route Table"
  }
}
resource "aws_route_table_association" "rt_associate_public" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.publicsub.*.id[count.index]
  route_table_id = aws_route_table.rt_public.id
}