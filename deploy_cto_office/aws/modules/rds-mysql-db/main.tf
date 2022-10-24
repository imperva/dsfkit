terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.region
}

resource "aws_db_subnet_group" "rds_db_sg" {
  name       = "${var.db_name}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids
  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_option_group" "impv_rds_db_pg" {
  name        = replace("${var.db_name}-pg", "_", "-")
  option_group_description = "RDS DB option group"
  engine_name = "mysql"
  major_engine_version = "5.7"
  
  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT,QUERY,QUERY_DDL,QUERY_DML,QUERY_DCL,QUERY_DML_NO_SELECT"
    }
    option_settings {
      name  = "SERVER_AUDIT_EXCL_USERS"
      value = "rdsadmin"
    }
  }
}

resource "aws_db_instance" "rds_db" {
  depends_on             = [aws_db_option_group.impv_rds_db_pg,aws_db_subnet_group.rds_db_sg]
  allocated_storage      = 10
  db_name                = var.db_name
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = var.username
  password               = var.password
  option_group_name      = aws_db_option_group.impv_rds_db_pg.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_mysql_access.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_db_sg.name
  identifier             = var.db_identifier
  publicly_accessible    = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

data "aws_subnet" "subnet" {
  id = var.rds_subnet_ids[0]
}

resource "aws_security_group" "rds_mysql_access" {
  description = "RDS MySQL Access"
  vpc_id      = data.aws_subnet.subnet.vpc_id

  tags = {
    Name = join("-", [var.db_name, "sg"])
  }
}

resource "aws_security_group_rule" "rds_mysql_access_rule" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidrs
  security_group_id = aws_security_group.rds_mysql_access.id
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
