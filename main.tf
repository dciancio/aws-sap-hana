# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}
# Declare the data source
data "template_file" "sysprep-bastion" {
  template = "${file("./helper_scripts/sysprep-bastion.sh")}"
  vars {
    rhak = "${var.rhak}"
    rhorg = "${var.rhorg}"
    ec2domain = "${var.ec2domain}"
    s3bucketname = "${var.s3bucketname}"
  }
}
data "template_file" "sysprep-sap-hana" {
  template = "${file("./helper_scripts/sysprep-sap-hana.sh")}"
  vars {
    rhak = "${var.rhak}"
    rhorg = "${var.rhorg}"
    ec2domain = "${var.ec2domain}"
  }
}
