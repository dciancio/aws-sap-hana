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
    ec2domain    = var.ec2domain
    s3bucketname = var.s3bucketname
  }
}

data "template_file" "sysprep-app_node" {
  template = file("./helper_scripts/sysprep-app_node.sh")
  vars = {
    rhak      = var.rhak
    rhorg     = var.rhorg
    ec2domain = var.ec2domain
  }
}

