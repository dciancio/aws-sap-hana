output "bastion_hostnames" {
  value = [aws_instance.bastion.*.public_dns]
}

