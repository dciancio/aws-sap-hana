data "aws_vpc" "default" {
  tags {
    Name = "${var.vpc_name}"
  }
}
data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.default.id}"
  tags {
    Name = "${var.clustername}-public-*"
  }
}
data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.default.id}"
  tags {
    Name = "${var.clustername}-private-*"
  }
}
