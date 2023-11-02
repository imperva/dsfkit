data "aws_subnet" "hub_main" {
  id       = var.subnet_ids.hub_main_subnet_id
  provider = aws.provider-1
}

data "aws_subnet" "hub_dr" {
  id       = var.subnet_ids.hub_dr_subnet_id
  provider = aws.provider-1
}

data "aws_subnet" "agentless_gw_main" {
  id       = var.subnet_ids.agentless_gw_main_subnet_id
  provider = aws.provider-2
}

data "aws_subnet" "agentless_gw_dr" {
  id       = var.subnet_ids.agentless_gw_dr_subnet_id
  provider = aws.provider-2
}

data "aws_subnet" "mx" {
  id       = var.subnet_ids.mx_subnet_id
  provider = aws.provider-1
}

data "aws_subnet" "agent_gw" {
  id       = var.subnet_ids.agent_gw_subnet_id
  provider = aws.provider-2
}

data "aws_subnet" "dra_admin" {
  id       = var.subnet_ids.dra_admin_subnet_id
  provider = aws.provider-1
}

data "aws_subnet" "dra_analytics" {
  id       = var.subnet_ids.dra_analytics_subnet_id
  provider = aws.provider-2
}
