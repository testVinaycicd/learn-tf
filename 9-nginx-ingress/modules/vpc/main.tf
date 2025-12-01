data "aws_caller_identity" "current" {}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.env}-${var.name}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-${var.name}"
  }
}

resource "aws_subnet" "main" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value["cidr"]
  availability_zone = each.value["zone"]

  tags = {
    Name  = each.key
    group = each.value["group"]
  }
}

resource "aws_route_table" "main" {
  for_each = var.subnets
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = each.key
  }
}

resource "aws_route_table_association" "main" {
  for_each       = var.subnets
  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.main[each.key].id
}

resource "aws_route" "igw" {
  count                  = length(local.public_route_table_ids)
  route_table_id         = local.public_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_vpc_peering_connection" "peer-to-default-vpc" {
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id   = aws_vpc.main.id
  vpc_id        = var.default_vpc["vpc_id"]
  auto_accept   = true
}

resource "aws_route" "in-main" {
  count                     = length(local.all_route_table_ids)
  route_table_id            = local.all_route_table_ids[count.index]
  destination_cidr_block    = var.default_vpc["vpc_cidr"]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-to-default-vpc.id
}

resource "aws_route" "in-default" {
  route_table_id            = var.default_vpc["routetable_id"]
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-to-default-vpc.id
}

resource "aws_eip" "ngw" {
  count  = length(local.public_subnet_ids)
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = length(local.public_subnet_ids)
  allocation_id = aws_eip.ngw[count.index].id
  subnet_id     = local.public_subnet_ids[count.index]

  tags = {
    Name = "${var.env}-${var.name}-${count.index + 1}"
  }
}


resource "aws_route" "ngw" {
  count                  = length(local.private_route_table_ids)
  route_table_id         = local.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

