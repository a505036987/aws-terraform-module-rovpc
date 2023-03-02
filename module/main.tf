provider "aws" {
  region = "eu-central-1"
}

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
  depends_on = [
    aws_vpc.wssdev-vpc
  ]
  count             = var.public_sn_count
  vpc_id            = aws_vpc.wssdev-vpc.id
  cidr_block        = "10.158.${96 + count.index}.0/24"
  availability_zone = element(["eu-central-1a", "eu-central-1c", "eu-central-1a"], count.index)
  tags = {
    Name = "WSS Public Subnet${count.index + 1}"
  }
}

# Creating private subnets
resource "aws_subnet" "privatesub" {
  count             = var.private_sn_count
  vpc_id            = aws_vpc.wssdev-vpc.id
  cidr_block        = "10.158.${100 + count.index}.0/24"
  availability_zone = element(["eu-central-1a", "eu-central-1c", "eu-central-1a"], count.index)
  tags = {
    Name = "WSS Private Subnet${count.index + 1}"
  }
}

# Creating workspace subnets
resource "aws_subnet" "workspacesub" {
  count             = var.workspace_sn_count
  vpc_id            = aws_vpc.wssdev-vpc.id
  cidr_block        = "10.158.${104 + count.index}.0/24"
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

resource "aws_nat_gateway" "asia-it-gw" {
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
  count = var.public_sn_count
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
# Creating Security Group 
resource "aws_security_group" "sg-public" {
  name   = "sg_public"
  vpc_id = aws_vpc.wssdev-vpc.id
  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
  }
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
  }
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
  }
  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-private" {
  name   = "sg_private"
  vpc_id = aws_vpc.wssdev-vpc.id
  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
  }
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
  }
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
  }
  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "sg_wssad" {
  name = "sg_workspaces_ad_access"
  description = "A security group that allows domain controller services on Microsoft Active Directory servers."
  vpc_id = aws_vpc.wssdev-vpc.id

  ingress {
    from_port = 1024
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "RPC"
  }
  ingress {
    from_port = 445
    to_port = 445
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "SMB"
  }
  ingress {
    from_port = 88
    to_port = 88
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "Kerberos"
  }
  ingress {
    from_port = 88
    to_port = 88
    protocol = "udp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "Kerberos"
  }
  ingress {
    from_port = 464
    to_port = 464
    protocol = "udp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "Kerberos password change"
  }
  ingress {
    from_port = 464
    to_port = 464
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "Kerberos password change"
  }
  ingress {
    from_port = 389
    to_port = 389
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "LDAP Server"
  }
  ingress {
    from_port = 389
    to_port = 389
    protocol = "udp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "LDAP Server"
  }
  ingress {
    from_port = 636
    to_port = 636
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "LDAP Server (SSL)"
  }
  ingress {
    from_port = 135
    to_port = 135
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "RPC"
  }
  ingress {
    from_port = 49152
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "RPC randomly allocated tcp high ports"
  }
  ingress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "W32Time"
  }
  ingress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "DNS"
  }
  ingress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "DNS"
  }
  ingress {
    from_port = 3268
    to_port = 3269
    protocol = "udp"
    cidr_blocks = ["10.158.0.0/16"]
    description = "LDAP GC and SSL"
  }

 ingress {
    from_port = 1024
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "RPC"
  }
  ingress {
    from_port = 445
    to_port = 445
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "SMB"
  }
  ingress {
    from_port = 88
    to_port = 88
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "Kerberos"
  }
  ingress {
    from_port = 88
    to_port = 88
    protocol = "udp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "Kerberos"
  }
  ingress {
    from_port = 464
    to_port = 464
    protocol = "udp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "Kerberos password change"
  }
  ingress {
    from_port = 464
    to_port = 464
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "Kerberos password change"
  }
  ingress {
    from_port = 389
    to_port = 389
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "LDAP Server"
  }
  ingress {
    from_port = 389
    to_port = 389
    protocol = "udp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "LDAP Server"
  }
  ingress {
    from_port = 636
    to_port = 636
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "LDAP Server (SSL)"
  }
  ingress {
    from_port = 135
    to_port = 135
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "RPC"
  }
  ingress {
    from_port = 49152
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "RPC randomly allocated tcp high ports"
  }
  ingress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "W32Time"
  }
  ingress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "DNS"
  }
  ingress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "DNS"
  }
  ingress {
    from_port = 3268
    to_port = 3269
    protocol = "udp"
    cidr_blocks = ["10.18.130.106/32"]
    description = "LDAP GC and SSL"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
