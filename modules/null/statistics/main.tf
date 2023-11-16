locals {
  host         = "https://stats.dsfkitimperva.com"
  resource     = "dsfkit_usage_stats"
  url          = join("/", [local.host, local.resource])

  id = var.id == null ? random_uuid.stats_id.result : var.id

  enable_statistics = true
}

resource "random_uuid" "stats_id" {
}

locals {
  payload = jsonencode({
    "id" : local.id
    "deployment_name" : var.deployment_name == null ? null : local.hashed_deployment_name,
    "artifact" : var.artifact
    "product" : var.product
    "resource_type" : var.resource_type
    "account_id" : sha256(var.account_id)
    "platform" : var.platform
    "location" : var.location
    "status" : var.status
    "additional_info" : var.additional_info
  })
}

resource "null_resource" "curl_request" {
  count = local.enable_statistics ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
              curl -X POST \
                  -H "Content-Type: application/json" \
                  --data '${local.payload}' \
                  '${local.url}' || true
              EOT
  }
}

## http data source can fail resulting a user's deployment to fail. That's why we prefer to use curl directly with 
# data "http" "statistics" {
#   url    = local.url
#   method = "POST"

#   request_headers = {
#     Accept    = "application/json"
#     x-api-key = local.header_value
#   }

#   request_body = local.payload
#   ignore_errors = true
# }
