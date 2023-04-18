data "template_file" "analytics_bootstrap" {
  template = file("${path.module}/analytics_bootstrap.tpl")
  vars = {
    registration_password = var.registration_password
    analytics_user = var.analytics_user
    analytics_password = var.analytics_password
    admin_server_ip = var.admin_server_ip
  }
}
resource "aws_instance" "dra_analytics" {
  ami           = var.analytics_ami_id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = ["${aws_security_group.analytics-server-demo.id}"]
  key_name = var.ssh_key_pair.ssh_public_key_name
  user_data = data.template_file.analytics_bootstrap.rendered
  tags = {
    Name = "DRA-Analytics-server"
    stage = "Test"
  }
}
