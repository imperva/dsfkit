data "template_file" "admin_bootstrap" {
  template = file("${path.module}/admin_bootstrap.tpl")
  vars = {
    registration_password = var.registration_password
  }
}
resource "aws_instance" "dra_admin" {
  ami           = var.admin_ami_id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = ["${aws_security_group.admin-server-demo.id}"]
  key_name = var.ssh_key_pair.ssh_public_key_name
  user_data = data.template_file.admin_bootstrap.rendered

  tags = {
    Name = "DRA-Admin-server"
    stage = "Test"
  }
}