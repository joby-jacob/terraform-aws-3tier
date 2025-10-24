data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-igw" }
}

# Create public & private subnets across N AZs
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_subnet" "public" {
  for_each = { for idx, az in local.azs : idx => az }
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(var.cidr_block, 8, each.key)  # 10.0.x.0/24
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = { for idx, az in local.azs : idx => az }
  vpc_id            = aws_vpc.this.id
  availability_zone = each.value
  cidr_block        = cidrsubnet(var.cidr_block, 8, each.key + 100) # 10.0.(100+x).0/24
  tags = { Name = "${var.name}-private-${each.key}" }
}

# NAT per AZ (simple: 1 NAT for all to reduce cost -> use first public subnet)
resource "aws_eip" "nat" { domain = "vpc" }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags = { Name = "${var.name}-nat" }
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route { cidr_block = "0.0.0.0/0" gateway_id = aws_internet_gateway.igw.id }
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route { cidr_block = "0.0.0.0/0" nat_gateway_id = aws_nat_gateway.nat.id }
  tags = { Name = "${var.name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
