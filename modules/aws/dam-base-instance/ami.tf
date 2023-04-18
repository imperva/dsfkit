data "aws_ami" "selected-ami" {
  owners = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["SecureSphere-${var.dam_version}*"]
  }

  # Filter for ami using the local.dammxbyolRegion2Ami map
  #   filter {
  #     name   = "image-id"
  #     values = [lookup(local.dammxbyolRegion2Ami[data.aws_region.current.name], "ImageId")]
  #   }

  # Filter for ami using the CTT api
  #   filter {
  #     name   = "image-id"
  #     values = [data.external.ami.result.ami]
  #   }
}

# locals {
#   dammxbyolRegion2Ami = {
#     us-west-1 = {
#       ImageId = "ami-060d440817f97f6a5"
#     }
#     us-west-2 = {
#       ImageId = "ami-0d3d795b13aa624f9"
#     }
#   }
# }

####################################
#### Get AMI using ctt url:     ####
####################################
# locals {
#     ctt_url = "1tczgrjvuj.execute-api.us-east-1.amazonaws.com"
#   cmd = <<EOF
#   curl 'https://${local.ctt_url}/cloud-template-tool-dam/getBuilds' -X POST | jq '.builds[] | select(.region == "${data.aws_region.current.name}" and .build == "${var.dam_version}")'
# EOF
# }

# data "external" "ami" {
#   program = ["bash", "-c", local.cmd]

#   query = {
#     ami = "ami"
#   }

#   lifecycle {
#     postcondition {
#       condition     = self.result.ami != ""
#       error_message = "Failed to get ami"
#     }
#   }
# }

