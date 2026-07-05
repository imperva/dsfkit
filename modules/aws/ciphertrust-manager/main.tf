locals {
  web_console_username         = "admin"
  web_console_default_password = "admin"

  security_group_ids = concat(
    [for sg in aws_security_group.sg : sg.id],
  var.security_group_ids)

  public_ip = (var.attach_persistent_public_ip ?
    (length(aws_eip.dsf_instance_eip) > 0 ? aws_eip.dsf_instance_eip[0].public_ip : null) :
  aws_instance.cipthertrust_manager_instance.public_ip)
  public_dns = (var.attach_persistent_public_ip ?
    (length(aws_eip.dsf_instance_eip) > 0 ? aws_eip.dsf_instance_eip[0].public_dns : null) :
  aws_instance.cipthertrust_manager_instance.public_dns)
  private_ip = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null

  cm_address = coalesce(local.public_ip, local.private_ip)
}

resource "aws_eip" "dsf_instance_eip" {
  count  = var.attach_persistent_public_ip ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = var.friendly_name })
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.attach_persistent_public_ip ? 1 : 0
  instance_id   = aws_instance.cipthertrust_manager_instance.id
  allocation_id = aws_eip.dsf_instance_eip[0].id
}

resource "aws_instance" "cipthertrust_manager_instance" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair
  root_block_device {
    volume_size           = var.ebs.volume_size
    volume_type           = var.ebs.volume_type
    iops                  = var.ebs.iops
    encrypted             = var.ebs.encrypted
    delete_on_termination = true
  }
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  disable_api_termination = true
  force_destroy           = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags        = merge(var.tags, { Name : var.friendly_name })
  volume_tags = merge(var.tags, { Name : var.friendly_name })

  lifecycle {
    ignore_changes = [ami]
  }
  depends_on = [
    aws_network_interface.eni,
    aws_eip.dsf_instance_eip,
    data.aws_ami.selected-ami
  ]
}

resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
  tags            = var.tags
}

resource "null_resource" "set_password" {
  provisioner "local-exec" {
    # NOTE: This script intentionally never exits with a non-zero status.
    # If it did, Terraform would mark this resource (and this whole apply)
    # as failed, which can prevent independent resources elsewhere in the
    # graph (e.g. Route53 DNS records for this and other instances) from
    # ever being created/scheduled in the same apply. Any failure here is
    # logged clearly instead, so operators can detect it (e.g. by scanning
    # apply logs for "ERROR:"), without blocking the rest of the deployment.
    command = <<EOF
    #!/bin/bash -x

    # Wait up to 10 minutes for API to respond
    echo "Waiting for service API to become reachable..."
    for i in {1..60}; do
      response=$(curl -k -s --connect-timeout 5 https://${local.cm_address}/api/v1/system/services/status 2>/dev/null) || true
      if [ -n "$response" ]; then
        echo "CipherTrust Manager API is reachable."
        break
      fi
      echo "[$i] CipherTrust Manager API unreachable, retrying in 10s..."
      sleep 10
    done

    if [ -z "$response" ]; then
      echo "ERROR: CipherTrust Manager API did not become reachable in time. Skipping password change; this Terraform resource will still report success so other independent resources (e.g. DNS records) can be created."
      exit 0
    fi

    # Wait up to 10 minutes for status = "started"
    echo "Waiting for CipherTrust Manager services to start..."
    for i in {1..60}; do
      response=$(curl -k -s --connect-timeout 5 https://${local.cm_address}/api/v1/system/services/status 2>/dev/null) || true
      if [ -z "$response" ]; then
        echo "[$i] Services status API unreachable, retrying in 10s..."
        sleep 10
        continue
      fi

      # Remove carriage returns and newlines from the response since jq does not handle them well
      clean_response=$${response//'\r'/}
      clean_response=$${clean_response//'\n'/' '}
      SERVICE_STATUS=$(echo "$clean_response" | jq -r '.status')
      if [ "$SERVICE_STATUS" = "started" ]; then
        echo "Service status is 'started'. Proceeding with password change."
        response=$(curl -k -s -w "\n%%{http_code}" -X PATCH "https://${local.cm_address}/api/v1/auth/changepw" --header 'Content-Type: application/json' \
          --data "{\"username\": \"admin\", \"password\": \"$PASSWORD\", \"new_password\": \"$NEW_PASSWORD\"}")

        BODY=$(echo "$response" | sed '$d')
        STATUS=$(echo "$response" | tail -n1)
        if [ "$STATUS" -ge 200 ] && [ "$STATUS" -lt 300 ]; then
          echo "CipherTrust Manager password was set successfully"
          exit 0
        else
          echo "ERROR: Request failed with HTTP status $STATUS. This can happen if the CM instance's admin password was already changed (e.g. reused/custom AMI). Not failing the apply so other independent resources (e.g. DNS records) can still be created."
          echo "$BODY"
          exit 0
        fi
      fi

      echo "[$i] Services status: $SERVICE_STATUS... retrying in 10s"
      sleep 10
    done

    echo "ERROR: Services did not start in time. Skipping password change; this Terraform resource will still report success so other independent resources (e.g. DNS records) can be created."
    exit 0
    EOF

    interpreter = ["bash", "-c"]

    environment = {
      PASSWORD     = local.web_console_default_password
      NEW_PASSWORD = nonsensitive(var.cm_password)
    }
  }

  depends_on = [
    aws_instance.cipthertrust_manager_instance,
    aws_network_interface.eni,
    aws_eip_association.eip_assoc
  ]
}

