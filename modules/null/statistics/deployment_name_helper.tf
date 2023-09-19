locals {
    deployment_name = lower(var.deployment_name != null ? var.deployment_name : "NA")
    block_list = [
        "dam",
        "mx",
        "cluster",
        "gw",
        "gateway",
        "agent",
        "dra",
        "analytics",
        "admin",
        "dr",
        "main",
        "primary",
        "secondary",
        "hub",
        "dsf",
        "imperva",
        "agentless",
    ]
    tokens = [for t in split("-", local.deployment_name) : t if !contains(local.block_list, t) && (!can(parseint(t, 10)) || length(t) > 3)] # Drop if token is 3 digits number or a blocked term
    hashed_deployment_name = sha256(join("", local.tokens))
}