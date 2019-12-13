data "template_file" "app_nodes" {
  count    = var.app_node_count
  template = file("${path.cwd}/helper_scripts/app_nodes.template")
  vars = {
    app_node = element(aws_instance.app_node.*.private_dns, count.index)
  }
}

data "template_file" "inventory" {
  template = file("${path.cwd}/helper_scripts/ansible-hosts.template")
  vars = {
    app_nodes = join("", data.template_file.app_nodes.*.rendered)
  }
}

resource "local_file" "inventory" {
  content  = data.template_file.inventory.rendered
  filename = "${path.cwd}/inventory/ansible-hosts"
}

