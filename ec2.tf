resource "aws_instance" "bastion" {
  count                       = var.bastion_count
  ami                         = var.aws_amis[var.aws_region]
  instance_type               = var.bastion_instance_type
  subnet_id                   = element(tolist(data.aws_subnet_ids.public.ids), count.index)
  security_groups             = [aws_security_group.sec_bastion.id]
  key_name                    = var.keypair
  user_data                   = data.template_file.sysprep-bastion.rendered
  iam_instance_profile        = var.instancerole
  associate_public_ip_address = true
  tags = {
    "Name" = "${var.vpcprefix}-${var.app_name}-bastion-${count.index}"
  }
  volume_tags = {
    "Name" = "${var.vpcprefix}-${var.app_name}-bastion-${count.index}"
  }
  ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = true
  }
  provisioner "file" {
    source      = "${path.cwd}/inventory/ansible-hosts"
    destination = "~/hosts"
    connection {
      host = self.public_ip
      type = "ssh"
      user = "ec2-user"
    }
  }
  depends_on = [local_file.inventory]
}

resource "aws_instance" "app_node" {
  count                = var.app_node_count
  ami                  = var.aws_amis[var.aws_region]
  instance_type        = var.app_node_instance_type
  subnet_id            = element(tolist(data.aws_subnet_ids.private.ids), count.index)
  security_groups      = [aws_security_group.sec_app_node.id]
  key_name             = var.keypair
  user_data            = data.template_file.sysprep-app_node.rendered
  iam_instance_profile = var.instancerole
  tags = {
    "Name" = "${var.vpcprefix}-${var.app_name}-node-${count.index}"
  }
  volume_tags = {
    "Name" = "${var.vpcprefix}-${var.app_name}-node-${count.index}"
  }
  ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_type           = "gp2"
    volume_size           = 150
    delete_on_termination = true
  }
}

