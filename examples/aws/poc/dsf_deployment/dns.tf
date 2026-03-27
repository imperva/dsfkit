##############################
####    DNS / CNAME       ####
##############################
#
# Creates CNAME records in Route53 for all public-facing instances.
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
  # Keys MUST be known at plan time for for_each. We use simple suffixes
  # ("hub", "mx", etc.) and construct the full CNAME name in the resource.
  dns_record_targets = local.dns_enabled ? merge(
    var.enable_sonar ? {
      "hub" = module.hub_main[0].public_dns
    } : {},
    var.enable_sonar && var.hub_hadr ? {
      "hub-dr" = module.hub_dr[0].public_dns
    } : {},
    var.enable_dam ? {
      "mx" = module.mx[0].public_dns
    } : {},
    var.enable_dra ? {
      "dra-admin" = module.dra_admin[0].public_dns
    } : {},
    var.enable_ciphertrust ? {
      for idx, val in module.ciphertrust_manager :
      "cm-${idx}" => val.public_dns
    } : {},
    var.enable_ciphertrust ? {
      for key, val in module.cte_ddc_agents :
      key => val.public_dns
    } : {},
  ) : {}

  # DNS hostnames for use in outputs
  # When DNS is configured, returns CNAME hostname; otherwise returns original public_dns
  dns_hub_main  = local.dns_enabled ? "${local.deployment_name_salted}-hub.${var.dns_zone_domain}" : try(module.hub_main[0].public_dns, null)
  dns_hub_dr    = local.dns_enabled ? "${local.deployment_name_salted}-hub-dr.${var.dns_zone_domain}" : try(module.hub_dr[0].public_dns, null)
  dns_mx        = local.dns_enabled ? "${local.deployment_name_salted}-mx.${var.dns_zone_domain}" : try(module.mx[0].public_dns, null)
  dns_dra_admin = local.dns_enabled ? "${local.deployment_name_salted}-dra-admin.${var.dns_zone_domain}" : try(module.dra_admin[0].public_dns, null)
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
