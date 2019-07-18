resource "aws_security_group" "sec_bastion" {
  name        = "${var.vpcprefix}-${var.app_name}-bastion-sg"
  description = "Used for bastion instance"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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
  tags = {
    "Name" = "${var.vpcprefix}-${var.app_name}-bastion-sg"
  }
}

resource "aws_security_group" "sec_app_node" {
  name        = "${var.vpcprefix}-${var.app_name}-node-sg"
  description = "Used for application node instances"
  vpc_id      = data.aws_vpc.default.id
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
  tags = {
    "Name" = "${var.vpcprefix}-${var.app_name}-node-sg"
  }
}

