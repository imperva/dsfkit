##############################
####    DNS / CNAME       ####
##############################
#
# Creates CNAME records in Route53 for public-facing instances.
# This enables access through zScaler Dedicated IP which blocks direct
# AWS public IP/DNS access.
#
# Usage:
#   dns_zone_domain only       → outputs show records to create manually
#   dns_zone_domain + role_arn → records auto-created in Route53

# Cross-account Route53 provider
# When dns_route53_role_arn is null, assume_role is effectively skipped.
# All resources using this provider have count/for_each gated behind dns_auto_create,
# so no Route53 API calls are made when DNS is not configured.
provider "aws" {
  alias = "dns"
  assume_role {
    role_arn = var.dns_route53_role_arn
  }
}

locals {
  dns_enabled     = var.dns_zone_domain != null
  dns_auto_create = var.dns_zone_domain != null && var.dns_route53_role_arn != null && var.dns_route53_zone_id != null

  # Build map: static-key => target-public-dns
  dns_record_targets = local.dns_enabled ? {
    "hub"    = module.hub_main.public_dns
    "hub-dr" = module.hub_dr.public_dns
  } : {}

  # DNS hostnames for use in outputs
  # When DNS is configured, returns CNAME hostname; otherwise returns original public_dns
  dns_hub_main = local.dns_enabled ? "${local.deployment_name_salted}-hub.${var.dns_zone_domain}" : module.hub_main.public_dns
  dns_hub_dr   = local.dns_enabled ? "${local.deployment_name_salted}-hub-dr.${var.dns_zone_domain}" : module.hub_dr.public_dns
}

resource "aws_route53_record" "dns" {
  for_each = local.dns_auto_create ? local.dns_record_targets : {}
  provider = aws.dns
  zone_id  = var.dns_route53_zone_id
  name     = "${local.deployment_name_salted}-${each.key}"
  type     = "CNAME"
  ttl      = 300
  records  = [each.value]
}
