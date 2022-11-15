output "installer_machine_ssh_command" {
  value = join("", ["ssh -i ${resource.local_sensitive_file.installer_ssh_key.filename} ec2-user@", resource.aws_instance.installer_machine.public_ip])
}

output "logs_tail_ssh_command" {
  value = join("", ["ssh -o StrictHostKeyChecking='no' -i ${resource.local_sensitive_file.installer_ssh_key.filename} ec2-user@", resource.aws_instance.installer_machine.public_ip, " -C 'sudo tail -f /var/log/user-data.log'"])
}
