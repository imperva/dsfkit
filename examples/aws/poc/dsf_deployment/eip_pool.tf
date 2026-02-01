# Query AWS for all EIPs in the pool
data "aws_eips" "pool" {
  count = var.use_eip_pool ? 1 : 0

  filter {
    name   = "tag:Pool"
    values = [var.eip_pool_tag]
  }
}

# Create locals to distribute allocation IDs to resources
locals {
  # Get list of allocation IDs from pool (only unassociated ones to avoid conflicts)
  eip_pool_all_allocation_ids = var.use_eip_pool ? data.aws_eips.pool[0].allocation_ids : []

  # Calculate how many IPs we need
  eip_count_needed = (
    (var.enable_sonar ? 1 : 0) +                                  # hub_main
    (var.enable_sonar && var.hub_hadr ? 1 : 0) +                  # hub_dr
    (var.enable_dam ? 1 : 0) +                                    # mx
    (var.enable_dra ? 1 : 0) +                                    # dra_admin
    (var.enable_ciphertrust ? var.ciphertrust_manager_count : 0) + # ciphertrust_managers
    (var.enable_ciphertrust ? (                                   # cte/ddc agents
      var.cte_ddc_agents_linux_count +
      var.cte_agents_linux_count +
      var.ddc_agents_linux_count +
      var.cte_ddc_agents_windows_count +
      var.cte_agents_windows_count +
      var.ddc_agents_windows_count
    ) : 0)
  )

  # Validate we have enough IPs
  eip_pool_valid = !var.use_eip_pool || length(local.eip_pool_all_allocation_ids) >= local.eip_count_needed

  # Distribute allocation IDs to resources
  # Use null if use_eip_pool is false (modules will create new EIPs)

  # Index counter for distributing IPs
  hub_main_eip_index = 0
  hub_dr_eip_index   = var.enable_sonar ? 1 : 0
  mx_eip_index       = (var.enable_sonar ? 1 : 0) + (var.enable_sonar && var.hub_hadr ? 1 : 0)
  dra_admin_eip_index = (
    (var.enable_sonar ? 1 : 0) +
    (var.enable_sonar && var.hub_hadr ? 1 : 0) +
    (var.enable_dam ? 1 : 0)
  )
  ciphertrust_manager_eip_start_index = (
    (var.enable_sonar ? 1 : 0) +
    (var.enable_sonar && var.hub_hadr ? 1 : 0) +
    (var.enable_dam ? 1 : 0) +
    (var.enable_dra ? 1 : 0)
  )
  cte_agent_eip_start_index = (
    (var.enable_sonar ? 1 : 0) +
    (var.enable_sonar && var.hub_hadr ? 1 : 0) +
    (var.enable_dam ? 1 : 0) +
    (var.enable_dra ? 1 : 0) +
    (var.enable_ciphertrust ? var.ciphertrust_manager_count : 0)
  )

  # Assign specific allocation IDs to each resource
  hub_main_eip_allocation_id    = var.use_eip_pool && var.enable_sonar ? local.eip_pool_all_allocation_ids[local.hub_main_eip_index] : null
  hub_dr_eip_allocation_id      = var.use_eip_pool && var.enable_sonar && var.hub_hadr ? local.eip_pool_all_allocation_ids[local.hub_dr_eip_index] : null
  mx_eip_allocation_id          = var.use_eip_pool && var.enable_dam ? local.eip_pool_all_allocation_ids[local.mx_eip_index] : null
  dra_admin_eip_allocation_id   = var.use_eip_pool && var.enable_dra ? local.eip_pool_all_allocation_ids[local.dra_admin_eip_index] : null

  # For CipherTrust Managers, create a list of allocation IDs
  ciphertrust_manager_eip_allocation_ids = var.use_eip_pool && var.enable_ciphertrust ? [
    for i in range(var.ciphertrust_manager_count) :
    local.eip_pool_all_allocation_ids[local.ciphertrust_manager_eip_start_index + i]
  ] : []

  # For CTE/DDC agents, create a map of allocation IDs keyed by agent ID
  # This matches the structure of local.all_agent_instances_map from cte_ddc_agents.tf
  cte_agent_eip_allocation_ids = var.use_eip_pool && var.enable_ciphertrust ? {
    for idx, instance_id in keys(local.all_agent_instances_map) :
    instance_id => local.eip_pool_all_allocation_ids[local.cte_agent_eip_start_index + idx]
  } : {}
}

# Validation check
resource "null_resource" "eip_pool_validation" {
  count = var.use_eip_pool ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.eip_pool_valid
      error_message = <<EOF
EIP Pool Error: Not enough IPs in pool!
  Pool tag: ${var.eip_pool_tag}
  IPs available: ${length(local.eip_pool_all_allocation_ids)}
  IPs needed: ${local.eip_count_needed}

Breakdown of IPs needed:
  - Hub Main: ${var.enable_sonar ? 1 : 0}
  - Hub DR: ${var.enable_sonar && var.hub_hadr ? 1 : 0}
  - MX: ${var.enable_dam ? 1 : 0}
  - DRA Admin: ${var.enable_dra ? 1 : 0}
  - CipherTrust Managers: ${var.enable_ciphertrust ? var.ciphertrust_manager_count : 0}
  - CTE/DDC Agents: ${var.enable_ciphertrust ? (var.cte_ddc_agents_linux_count + var.cte_agents_linux_count + var.ddc_agents_linux_count + var.cte_ddc_agents_windows_count + var.cte_agents_windows_count + var.ddc_agents_windows_count) : 0}

Please allocate more EIPs with tag Pool=${var.eip_pool_tag}:
  aws ec2 allocate-address --domain vpc --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Pool,Value=${var.eip_pool_tag}}]'
EOF
    }
  }
}
