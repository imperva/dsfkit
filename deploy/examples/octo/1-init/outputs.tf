output "region" { value = var.region }
output "environment" { value = var.environment }
output "key_pair" { value = var.key_pair }
output "key_pair_pem_local_path" { value = var.key_pair_pem_local_path }
output "s3_bucket" { value = var.s3_bucket }
output "dsf_passwords_secret_name" { value = "${var.environment}/dsf_passwords" }
output "rds_passwords_secret_name" { value = "${var.environment}/dsf_passwords" }
output "dsf_passwords" { value = resource.aws_secretsmanager_secret_version.dsf_passwords.id }