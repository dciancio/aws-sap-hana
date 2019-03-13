data "aws_security_group" "sec_bastion" {
  vpc_id = "${data.aws_vpc.default.id}"
  tags {
    Name = "${var.clustername}-bastion-sg"
  }
}
resource "aws_security_group" "sec_sap-hana" {
  name        = "${var.clustername}-sap-hana-sg"
  description = "Used for SAP HANA instances"
  vpc_id      = "${data.aws_vpc.default.id}"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags {
    "Name" = "${var.clustername}-sap-hana-sg"
  }
}
