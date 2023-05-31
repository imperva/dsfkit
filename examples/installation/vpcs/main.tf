provider "aws" {
  region = "us-west-2"
  alias  = "us-west-2"
}

locals {
  name                     = "eytan-for-tmobile"
  vpc_ip_range_us_west_2   = "10.1.0.0/16"
  public_subnet_us_west_2  = ["10.1.0.0/24"]
  private_subnet_us_west_2 = ["10.1.1.0/24", "10.1.2.0/24"]
}

data "aws_availability_zones" "available_us_west_2" {
  state    = "available"
  provider = aws.us-west-2
}

data "aws_caller_identity" "owner_us_west_2" {
  provider = aws.us-west-2
}

module "vpc_us_west_2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = local.name
  cidr = local.vpc_ip_range_us_west_2

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(data.aws_availability_zones.available_us_west_2.names, 0, 2)
  private_subnets = local.private_subnet_us_west_2
  public_subnets  = local.public_subnet_us_west_2

  providers = {
    aws = aws.us-west-2
  }
}

# us-west-1

provider "aws" {
  region = "us-west-1"
  alias  = "us-west-1"
}

locals {
  vpc_ip_range_us_west_1   = "10.0.0.0/16"
  public_subnet_us_west_1  = ["10.0.0.0/24"]
  private_subnet_us_west_1 = ["10.0.1.0/24", "10.0.2.0/24"]
}

data "aws_availability_zones" "available_us_west_1" {
  state    = "available"
  provider = aws.us-west-1
}

module "vpc_us_west_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = local.name
  cidr = local.vpc_ip_range_us_west_1

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(data.aws_availability_zones.available_us_west_1.names, 0, 2)
  private_subnets = local.private_subnet_us_west_1
  public_subnets  = local.public_subnet_us_west_1

  providers = {
    aws = aws.us-west-1
  }
}

resource "aws_vpc_peering_connection" "peering_us_west_1" {
  vpc_id = module.vpc_us_west_1.vpc_id

  peer_vpc_id   = module.vpc_us_west_2.vpc_id
  peer_owner_id = data.aws_caller_identity.owner_us_west_2.account_id
  peer_region   = "us-west-2"

  provider = aws.us-west-1
}

resource "aws_vpc_peering_connection_accepter" "peering_us_west_1" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_west_1.id
  auto_accept               = true
  provider                  = aws.us-west-2
}

resource "aws_route" "us_west_1_to_us_west_2" {
  for_each                  = { "1" : module.vpc_us_west_1.private_route_table_ids[0], "2" : module.vpc_us_west_1.public_route_table_ids[0] }
  route_table_id            = each.value
  destination_cidr_block    = local.vpc_ip_range_us_west_2
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_west_1.id
  provider                  = aws.us-west-1
}

resource "aws_route" "us_west_2_to_us_west_1" {
  for_each                  = { "1" : module.vpc_us_west_2.private_route_table_ids[0], "2" : module.vpc_us_west_2.public_route_table_ids[0] }
  route_table_id            = each.value
  destination_cidr_block    = local.vpc_ip_range_us_west_1
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_west_1.id
  provider                  = aws.us-west-2
}

# us-east-1
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

locals {
  vpc_ip_range_us_east_1   = "10.3.0.0/16"
  public_subnet_us_east_1  = ["10.3.0.0/24"]
  private_subnet_us_east_1 = ["10.3.1.0/24", "10.3.2.0/24"]
}

data "aws_availability_zones" "available_us_east_1" {
  state    = "available"
  provider = aws.us-east-1
}

module "vpc_us_east_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = local.name
  cidr = local.vpc_ip_range_us_east_1

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(data.aws_availability_zones.available_us_east_1.names, 0, 2)
  private_subnets = local.private_subnet_us_east_1
  public_subnets  = local.public_subnet_us_east_1

  providers = {
    aws = aws.us-east-1
  }
}

resource "aws_vpc_peering_connection" "peering_us_east_1" {
  vpc_id = module.vpc_us_east_1.vpc_id

  peer_vpc_id   = module.vpc_us_west_2.vpc_id
  peer_owner_id = data.aws_caller_identity.owner_us_west_2.account_id
  peer_region   = "us-west-2"

  provider = aws.us-east-1
}

resource "aws_vpc_peering_connection_accepter" "peering_us_east_1" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_east_1.id
  auto_accept               = true
  provider                  = aws.us-west-2
}

resource "aws_route" "us_east_1_to_us_west_2" {
  for_each                  = { "1" : module.vpc_us_east_1.private_route_table_ids[0], "2" : module.vpc_us_east_1.public_route_table_ids[0] }
  route_table_id            = each.value
  destination_cidr_block    = local.vpc_ip_range_us_west_2
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_east_1.id
  provider                  = aws.us-east-1
}

resource "aws_route" "us_west_2_to_us_east_1" {
  for_each                  = { "1" : module.vpc_us_west_2.private_route_table_ids[0], "2" : module.vpc_us_west_2.public_route_table_ids[0] }
  route_table_id            = each.value
  destination_cidr_block    = local.vpc_ip_range_us_east_1
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_east_1.id
  provider                  = aws.us-west-2
}

# us-east-2
provider "aws" {
  region = "us-east-2"
  alias  = "us-east-2"
}

locals {
  vpc_ip_range_us_east_2   = "10.4.0.0/16"
  public_subnet_us_east_2  = ["10.4.0.0/24"]
  private_subnet_us_east_2 = ["10.4.1.0/24", "10.4.2.0/24"]
}

data "aws_availability_zones" "available_us_east_2" {
  state    = "available"
  provider = aws.us-east-2
}

module "vpc_us_east_2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = local.name
  cidr = local.vpc_ip_range_us_east_2

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(data.aws_availability_zones.available_us_east_2.names, 0, 2)
  private_subnets = local.private_subnet_us_east_2
  public_subnets  = local.public_subnet_us_east_2

  providers = {
    aws = aws.us-east-2
  }
}

resource "aws_vpc_peering_connection" "peering_us_east_2" {
  vpc_id = module.vpc_us_east_2.vpc_id

  peer_vpc_id   = module.vpc_us_west_2.vpc_id
  peer_owner_id = data.aws_caller_identity.owner_us_west_2.account_id
  peer_region   = "us-west-2"

  provider = aws.us-east-2
}

resource "aws_vpc_peering_connection_accepter" "peering_us_east_2" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_east_2.id
  auto_accept               = true
  provider                  = aws.us-west-2
}

resource "aws_route" "us_east_2_to_us_west_2" {
  for_each                  = { "1" : module.vpc_us_east_2.private_route_table_ids[0], "2" : module.vpc_us_east_2.public_route_table_ids[0] }
  route_table_id            = each.value
  destination_cidr_block    = local.vpc_ip_range_us_west_2
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_east_2.id
  provider                  = aws.us-east-2
}

resource "aws_route" "us_west_2_to_us_east_2" {
  for_each                  = { "1" : module.vpc_us_west_2.private_route_table_ids[0], "2" : module.vpc_us_west_2.public_route_table_ids[0] }
  route_table_id            = each.value
  destination_cidr_block    = local.vpc_ip_range_us_east_2
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_east_2.id
  provider                  = aws.us-west-2
}