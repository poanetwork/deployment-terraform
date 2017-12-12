resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  tags {
    Name                 = "${var.infrastructure_name}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name                 = "${var.infrastructure_name}"
  }
}

resource "aws_default_route_table" "rtable" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name                 = "${var.infrastructure_name}"
  }
}

resource "aws_subnet" "a" {
  vpc_id            = "${aws_vpc.vpc.id}"
  availability_zone = "${var.region}a"
  cidr_block        = "10.0.1.0/24"

  tags {
    Name                 = "${var.infrastructure_name}"
  }
}

resource "aws_subnet" "b" {
  vpc_id            = "${aws_vpc.vpc.id}"
  availability_zone = "${var.region}b"
  cidr_block        = "10.0.2.0/24"

  tags {
    Name                 = "${var.infrastructure_name}"
  }
}

resource "aws_subnet" "c" {
  vpc_id            = "${aws_vpc.vpc.id}"
  availability_zone = "${var.region}c"
  cidr_block        = "10.0.3.0/24"

  tags {
    Name                 = "${var.infrastructure_name}"
  }
}
