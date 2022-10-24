terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.region
}

data "aws_iam_role" "iam_role" {
  name = var.dsf_iam_role_name
}

locals {
  asset_discovery  = {
    "sonark_aggregate": {
        "remove_limit": null
    },
    "root": {
      "run_type": "direct",
      "row_run": null,
      "bulk_run": null,
      "documents_to_import": [
        {
          "service": "AWS", 
          "asset_id": data.aws_iam_role.iam_role.arn,
          "asset_display_name": data.aws_iam_role.iam_role.name,
          "Server Type": "AWS",
          "asset_source": "AWS",
          "audit_pull_enabled": false,
          "jsonar_uid": var.gw1_uuid,
          "jsonar_uid_display_name": var.gw1_display_name,
          "Service Name": "aws",
          "Server IP": "unused_placeholder_value",
          "Server Host Name": "unused_placeholder_value",
          "admin_email": "admin@imperva.com",
          "Server Port": "443",
          "location": "${data.aws_iam_role.iam_role.name}-${var.region}",
          "region": var.region,
          "owned_by": "admin@imperva.com",
          "managed_by": "admin@imperva.com",
          "auth_mechanism":"default"
        }
      ]
    }
  }
  # rds_asset_json  = {
  #   "import": { 
  #     "documents_to_import": [
  #       {
  #         "asset_id": aws_rds_cluster.rds_db.arn,
  #         "asset_display_name": aws_rds_cluster.rds_db.cluster_identifier,
  #         "Server Type": "AWS RDS AURORA MYSQL CLUSTER",
  #         "Server IP": aws_rds_cluster.rds_db.arn,
  #         "Server Port": aws_rds_cluster.rds_db.port,
  #         "Server Host Name": aws_rds_cluster.rds_db.endpoint,
  #         "arn": aws_rds_cluster.rds_db.arn,
  #         "auth_mechanism": "password",
  #         "username": var.master_username,
  #         "password": var.master_password,
  #         "reason": "sonargateway",
  #         "database_name": aws_rds_cluster.rds_db.cluster_identifier,
  #         "admin_email": "admin@imperva.com",
  #         "jsonar_uid": var.gw1_uuid,
  #         "jsonar_uid_display_name": var.gw1_display_name
  #       }
  #     ] 
  #   }
  # }
  # log_group_json  = {
  #   "root": { 
  #     "run_type" : "direct", 
  #     "documents_to_import": [
  #       {
  #         "asset_id": aws_cloudwatch_log_group.audit.arn,
  #         "parent_asset_id": aws_rds_cluster.rds_db.arn,
  #         "asset_display_name": aws_cloudwatch_log_group.audit.name,
  #         "Server Type": "AWS LOG GROUP",
  #         "Server IP": "${aws_cloudwatch_log_group.audit.arn}:*",
  #         "Server Host Name": aws_rds_cluster.rds_db.endpoint,
  #         "arn": aws_cloudwatch_log_group.audit.arn,
  #         "region": var.region,
  #         "location": var.region,
  #         "Server Port": aws_rds_cluster.rds_db.port,
  #         "auth_mechanism": "default",
  #         "content_type": "AWS RDS AURORA MYSQL",
  #         "admin_email": "admin@imperva.com",
  #         "jsonar_uid": var.gw1_uuid,
  #         "jsonar_uid_display_name": var.gw1_display_name
  #       }
  #     ] 
  #   }
  # }
}

# Connect to hub with key_pair_pem, and call DSF API invoking import_discover_connect_gateway playbook to import the rds log group with the log_group_json above
resource "null_resource" "discover_and_connect" {
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file(var.key_pair_pem_local_path)
    host     = var.hub_ip
  }

  provisioner "remote-exec" {
    inline = [
      "curl -k -X POST --cacert /opt/jsonar/local/ssl/ca/ca.cert.pem --key /opt/jsonar/local/ssl/client/admin/key.pem --cert /opt/jsonar/local/ssl/client/admin/cert.pem -H 'Content-Type: application/json' https://localhost:27989/playbook-engine/playbooks/import_discover_connect_gateway/run?synchronous=true -d '${jsonencode(local.asset_discovery)}' --header 'Content-Type:application/json'"
    ]
  }
}

# # data "local_file" "sql_script" {
# #   filename = "${var.init_sql_file_path}"
# # }

# resource "null_resource" "db_setup" {
#   depends_on = [aws_db_instance.rds_db]
#   provisioner "local-exec" {
#     command = "mysql -h ${aws_db_instance.rds_db.endpoint} -u=${var.username} -p=${var.password} -P ${aws_db_instance.rds_db.port} mysql < ${var.init_sql_file_path}"
#   }
# }

# # Connect to hub with key_pair_pem, and call DSF API invoking invoke import_assets_api playbook to import the rds asset with the rds_asset_json above
# resource "null_resource" "remote_exec_rds_mysql_asset" {
#   depends_on = [aws_db_instance.rds_db]
#   connection {
#     type     = "ssh"
#     user     = "ec2-user"
#     private_key = file(var.key_pair_pem_local_path)
#     host     = var.hub_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "curl -X POST --cacert /opt/jsonar/local/ssl/ca/ca.cert.pem --key /opt/jsonar/local/ssl/client/admin/key.pem --cert /opt/jsonar/local/ssl/client/admin/cert.pem -H 'Content-Type: application/json' -X POST https://localhost:27989/playbook-engine/playbooks/import_assets_api/run?synchronous=true -d '${jsonencode(local.rds_asset_json)}'"
#       # "curl -k -H \"Authorization: Bearer your-bearer-token\" -H \"Content-Type: application/json\" -X POST https://localhost:8443/api/playbook-runner/playbook-engine/playbooks/import_discover_connect_gateway/run?synchronous=true -d '${jsonencode(local.register_json)}'"
#     ]
#   }
# }

# # Connect to hub with key_pair_pem, and call DSF API invoking import_discover_connect_gateway playbook to import the rds log group with the log_group_json above
# resource "null_resource" "remote_exec_log_group" {
#   depends_on = [aws_db_instance.rds_db,null_resource.remote_exec_rds_mysql_asset]
#   connection {
#     type     = "ssh"
#     user     = "ec2-user"
#     private_key = file(var.key_pair_pem_local_path)
#     host     = var.hub_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "curl -X POST --cacert /opt/jsonar/local/ssl/ca/ca.cert.pem --key /opt/jsonar/local/ssl/client/admin/key.pem --cert /opt/jsonar/local/ssl/client/admin/cert.pem -H 'Content-Type: application/json' -X POST https://localhost:27989/playbook-engine/playbooks/import_discover_connect_gateway/run?synchronous=true -d '${jsonencode(local.log_group_json)}'"
#       # "curl -k -H \"Authorization: Bearer your-bearer-token\" -H \"Content-Type: application/json\" -X POST https://localhost:8443/api/playbook-runner/playbook-engine/playbooks/import_assets_api/run?synchronous=true -d '${jsonencode(local.log_group)}'"
#     ]
#   }
# }

# DRA Listener
#cp $JSONAR_BASEDIR/etc/rsyslog.d/sonar/gateway/rulesets/imperva_dra_incidents.conf $JSONAR_LOCALDIR/gateway/rsyslog.d