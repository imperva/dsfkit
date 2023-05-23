locals {
  access_tokens = var.generate_access_tokens ? (var.resource_type != "hub" ? [] : [
    {
      "name" : "dam-to-hub",
      "scopes" : jsonencode(["archiver:service:upload"])
    },
    {
      "name" : "usc",
      "scopes" : jsonencode(["usc:access"])
    },
  ]) : []

  # Assign token ID per token:
  access_tokens_array = [
    for i in range(0, length(local.access_tokens)) : {
      index       = i,
      name        = local.access_tokens[i].name,
      scopes      = local.access_tokens[i].scopes,
      token       = random_uuid.access_tokens[i].result,
      secret_name = aws_secretsmanager_secret.access_token[i].name
    }
  ]
}

resource "random_uuid" "access_tokens" {
  count = length(local.access_tokens)
}