data "aws_ami" "selected-ami" {
  owners = ["496834581024"]
  filter {
    name   = "name"
    values = ["Imperva-DRA-Analytics-${var.dra_version}_*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
