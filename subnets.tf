resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr}.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.region}a"
  tags = {
    Name = "${var.organization_name}-public-subnetA"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr}.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.region}b"
  tags = {
    Name = "${var.organization_name}-public-subnetB"
  }
}

resource "aws_subnet" "private-a1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr}.2.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.region}a"
  tags = {
    Name = "${var.organization_name}-private-subnetA1"
  }
}

resource "aws_subnet" "private-b1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr}.3.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.region}b"
  tags = {
    Name = "${var.organization_name}-private-subnetB1"
  }
}

resource "aws_subnet" "private-a2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr}.4.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.region}a"
  tags = {
    Name = "${var.organization_name}-private-subnetA2"
  }
}

resource "aws_subnet" "private-b2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr}.5.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.region}b"
  tags = {
    Name = "${var.organization_name}-private-subnetB2"
  }
}

resource "aws_subnet" "private-a3" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr}.6.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.region}a"
  tags = {
    Name = "${var.organization_name}-private-subnetA3"
  }
}

resource "aws_subnet" "private-b3" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr}.7.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.region}b"
  tags = {
    Name = "${var.organization_name}-private-subnetB3"
  }
}
