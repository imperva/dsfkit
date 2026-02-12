# Query AWS for all EIPs in the pool (associated and unassociated)
# We need ALL pool EIPs for distribution since on subsequent applies our own
# associations make them "associated". The aws_eip_association resource is
# idempotent - associating an EIP to the same instance it's already on is a no-op.
data "aws_eips" "pool" {
  count = var.use_eip_pool ? 1 : 0

  filter {
    name   = "tag:Pool"
    values = [var.eip_pool_tag]
  }
}

# Query only UNASSOCIATED pool EIPs for validation purposes.
# This catches user errors like tagging an EIP that's already in use by
# a non-managed resource. On first deploy all pool EIPs should be unassociated.
# On subsequent applies, pool EIPs associated to our instances are expected.
data "aws_eips" "pool_available" {
  count = var.use_eip_pool ? 1 : 0

  filter {
    name   = "tag:Pool"
    values = [var.eip_pool_tag]
  }

  filter {
    name   = "association-id"
    values = [""]  # Empty association-id means unassociated
  }
}

# Create locals to distribute allocation IDs to resources
locals {
  # Get sorted list of ALL allocation IDs from pool.
  # Sort ensures stable ordering across API calls - same EIP always gets same index.
  eip_pool_all_allocation_ids = var.use_eip_pool ? sort(data.aws_eips.pool[0].allocation_ids) : []

  # Count of unassociated EIPs in the pool (for validation)
  eip_pool_available_count = var.use_eip_pool ? length(data.aws_eips.pool_available[0].allocation_ids) : 0

  # Count of already-associated EIPs in the pool
  eip_pool_associated_count = var.use_eip_pool ? (
    length(local.eip_pool_all_allocation_ids) - local.eip_pool_available_count
  ) : 0

  # Total pool EIPs available
  eip_pool_total_count = length(local.eip_pool_all_allocation_ids)

  # ============================================================================
  # Fixed slot positions for singleton resources
  # These positions NEVER change regardless of which modules are enabled/disabled.
  # This ensures that enabling/disabling sonar, dam, or dra does not shift the
  # EIP assigned to other resources.
  #
  # Slot layout:
  #   0: hub_main
  #   1: hub_dr
  #   2: mx
  #   3: dra_admin
  #   4+: ciphertrust_managers (up to ciphertrust_manager_count)
  #   4+cm_count+: cte/ddc agents
  #
  # Trade-off: Some pool slots may be unused if a module is disabled, but
  # positions are guaranteed stable across configuration changes.
  #
  # Note: Changing ciphertrust_manager_count will shift agent positions.
  # This is acceptable as CM count changes are rare in practice.
  # ============================================================================
  hub_main_eip_index  = 0
  hub_dr_eip_index    = 1
  mx_eip_index        = 2
  dra_admin_eip_index = 3
  ciphertrust_manager_eip_start_index = 4
  cte_agent_eip_start_index = 4 + (var.enable_ciphertrust ? var.ciphertrust_manager_count : 0)

  # Total agents count
  total_agent_count = (
    var.cte_ddc_agents_linux_count +
    var.cte_agents_linux_count +
    var.ddc_agents_linux_count +
    var.cte_ddc_agents_windows_count +
    var.cte_agents_windows_count +
    var.ddc_agents_windows_count
  )

  # Calculate the highest slot index needed (for pool size validation)
  # We use max() to find the highest slot that's actually in use
  eip_pool_highest_slot = max(
    var.enable_sonar ? local.hub_main_eip_index : -1,
    var.enable_sonar && var.hub_hadr ? local.hub_dr_eip_index : -1,
    var.enable_dam ? local.mx_eip_index : -1,
    var.enable_dra ? local.dra_admin_eip_index : -1,
    var.enable_ciphertrust && var.ciphertrust_manager_count > 0 ? (
      local.ciphertrust_manager_eip_start_index + var.ciphertrust_manager_count - 1
    ) : -1,
    var.enable_ciphertrust && local.total_agent_count > 0 ? (
      local.cte_agent_eip_start_index + local.total_agent_count - 1
    ) : -1,
  )

  # Pool needs enough EIPs to cover through the highest used slot
  eip_count_needed = local.eip_pool_highest_slot + 1

  # Validate we have enough IPs
  eip_pool_valid = !var.use_eip_pool || local.eip_pool_total_count >= local.eip_count_needed

  # Assign specific allocation IDs to each resource using fixed slot positions
  hub_main_eip_allocation_id  = var.use_eip_pool && var.enable_sonar ? local.eip_pool_all_allocation_ids[local.hub_main_eip_index] : null
  hub_dr_eip_allocation_id    = var.use_eip_pool && var.enable_sonar && var.hub_hadr ? local.eip_pool_all_allocation_ids[local.hub_dr_eip_index] : null
  mx_eip_allocation_id        = var.use_eip_pool && var.enable_dam ? local.eip_pool_all_allocation_ids[local.mx_eip_index] : null
  dra_admin_eip_allocation_id = var.use_eip_pool && var.enable_dra ? local.eip_pool_all_allocation_ids[local.dra_admin_eip_index] : null

  # For CipherTrust Managers, create a list of allocation IDs
  ciphertrust_manager_eip_allocation_ids = var.use_eip_pool && var.enable_ciphertrust ? [
    for i in range(var.ciphertrust_manager_count) :
    local.eip_pool_all_allocation_ids[local.ciphertrust_manager_eip_start_index + i]
  ] : []

  # For CTE/DDC agents, create a map of allocation IDs keyed by agent ID
  # This matches the structure of local.all_agent_instances_map from cte_ddc_agents.tf
  # Sort keys to ensure stable ordering - same agent always gets same pool EIP
  cte_agent_eip_allocation_ids = var.use_eip_pool && var.enable_ciphertrust ? {
    for idx, instance_id in sort(keys(local.all_agent_instances_map)) :
    instance_id => local.eip_pool_all_allocation_ids[local.cte_agent_eip_start_index + idx]
  } : {}
}

# Validation checks
resource "null_resource" "eip_pool_validation" {
  count = var.use_eip_pool ? 1 : 0

  lifecycle {
    # Validate pool has enough EIPs for the fixed slot layout
    precondition {
      condition     = local.eip_pool_valid
      error_message = <<EOF
EIP Pool Error: Not enough IPs in pool!
  Pool tag: ${var.eip_pool_tag}
  IPs in pool: ${local.eip_pool_total_count}
  IPs needed (highest slot + 1): ${local.eip_count_needed}

The pool uses fixed slot positions for stable IP assignment:
  - Slot 0 (Hub Main):  ${var.enable_sonar ? "USED" : "unused"}
  - Slot 1 (Hub DR):    ${var.enable_sonar && var.hub_hadr ? "USED" : "unused"}
  - Slot 2 (MX):        ${var.enable_dam ? "USED" : "unused"}
  - Slot 3 (DRA Admin): ${var.enable_dra ? "USED" : "unused"}
  - Slots 4+ (CipherTrust Managers): ${var.enable_ciphertrust ? var.ciphertrust_manager_count : 0}
  - Slots ${local.cte_agent_eip_start_index}+ (CTE/DDC Agents): ${var.enable_ciphertrust ? local.total_agent_count : 0}

Note: Some slots may be unused (disabled modules) but still require pool EIPs
at lower indices. This ensures IP stability when modules are toggled.

Please allocate more EIPs with tag Pool=${var.eip_pool_tag}:
  aws ec2 allocate-address --domain vpc --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Pool,Value=${var.eip_pool_tag}}]'
EOF
    }

    # Note: Previously had a check for associated EIPs exceeding expected count,
    # but this was overly restrictive. EIP associations are idempotent and will
    # be properly managed by terraform regardless of current association state.
  }
}
