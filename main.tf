locals {
  ec2domain = var.aws_region == "us-east-1" ? ".ec2.internal" : ""
}

# Specify the provider and access details
provider "aws" {
  region = var.aws_region
}

# Declare the data source
data "template_file" "sysprep-bastion" {
  template = file("./helper_scripts/sysprep-bastion.sh")
  vars = {
    rhak         = var.rhak
    rhorg        = var.rhorg
    ec2domain    = local.ec2domain
    s3bucketname = var.s3bucketname
  }
}

data "template_file" "sysprep-app_node" {
  template = file("./helper_scripts/sysprep-app_node.sh")
  vars = {
    rhak      = var.rhak
    rhorg     = var.rhorg
    ec2domain = local.ec2domain
  }
}

