# Public Route Table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.organization_name}-public-route-table"
  }
}

resource "aws_route_table_association" "public-subnet_a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-route-table.id
}
resource "aws_route_table_association" "public-subnet-b" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.public-route-table.id
}

# Private Route Table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.organization_name}-private-route-table"
  }
}

resource "aws_route_table_association" "private-subnet-a1" {
  subnet_id      = aws_subnet.private-a1.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet-b1" {
  subnet_id      = aws_subnet.private-b1.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet-a2" {
  subnet_id      = aws_subnet.private-a2.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet-b2" {
  subnet_id      = aws_subnet.private-b2.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet-a3" {
  subnet_id      = aws_subnet.private-a3.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet-b3" {
  subnet_id      = aws_subnet.private-b3.id
  route_table_id = aws_route_table.private-route-table.id
}