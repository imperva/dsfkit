data "aws_subnet" "hub_primary" {
  id       = var.subnet_ids.hub_primary_subnet_id
  provider = aws.provider-1
}

data "aws_subnet" "hub_secondary" {
  id       = var.subnet_ids.hub_secondary_subnet_id
  provider = aws.provider-1
}

data "aws_subnet" "agentless_gw_primary" {
  id       = var.subnet_ids.agentless_gw_primary_subnet_id
  provider = aws.provider-2
}

data "aws_subnet" "agentless_gw_secondary" {
  id       = var.subnet_ids.agentless_gw_secondary_subnet_id
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
