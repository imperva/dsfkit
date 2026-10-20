locals {
  ddc_active_node_commands = var.ddc_node_setup.enabled ? templatefile("${path.module}/ddc_active_node_setup.tftpl", {
    cm_node_address = var.ddc_node_setup.node_address
  }) : null

  # Build a single, deterministic, space-separated list of node addresses to probe
  # for cluster-join readiness. We probe via the public_address (which is what the
  # local terraform process can reach), but we still wait for ALL nodes — including
  # the joining ones — to report a healthy cluster-management API before we let the
  # ciphertrust_cluster resource attempt the join.
  #
  # The shell script below intentionally uses unauthenticated endpoints
  # (/healthz and /system/services/status) so we don't have to embed the admin
  # password in this string. If those endpoints look healthy, the cluster join
  # API is almost always ready as well.
  cluster_join_probe_addresses = join(" ", [for n in var.nodes : n.public_address])

  cluster_init_commands = length(var.nodes) > 1 ? templatefile("${path.module}/cluster_init.tftpl", {
    original_node_address = var.nodes[0].public_address
    original_node_host    = var.nodes[0].host
    all_node_addresses    = local.cluster_join_probe_addresses
  }) : null
}

# -----------------------------------------------------------------------------
# Stability fix (intermittent failure: "joining node is not ready, status: error")
#
# The ThalesGroup/ciphertrust provider's `ciphertrust_cluster` resource checks the
# services status only once, with no retry, and fails the whole apply if it isn't
# "started". When the provider creates the cluster on the original node itself, that
# node's cluster-raft service restarts and the node reports "error" for ~30s (then
# "starting" for 1m). The provider's check often lands in that window.
#
# To avoid it:
# - cluster_join_readiness waits until every node is stable before we start.
# - cluster_init activates a trial license on any unlicensed node (as the provider
#   does when it creates the cluster itself, but not when the cluster already
#   exists), creates the cluster on the original node and waits for the
#   cluster-raft restart to settle. ciphertrust_cluster then finds the cluster
#   already created and only joins the other nodes.
# -----------------------------------------------------------------------------
resource "null_resource" "cluster_join_readiness" {
  count = length(var.nodes) > 1 ? 1 : 0

  triggers = {
    # Re-run if the set of nodes changes
    nodes = local.cluster_join_probe_addresses
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -u
      addresses=(${local.cluster_join_probe_addresses})

      max_wait_seconds=900   # 15 minutes per node
      poll_interval=10
      consecutive_required=6 # ~60s of consecutive healthy responses

      check_node () {
        local addr="$1"
        local elapsed=0
        local consecutive_ok=0
        while [ "$elapsed" -lt "$max_wait_seconds" ]; do
          # /system/services/status: must be reachable AND status == "started"
          status_resp=$(curl -k -s --connect-timeout 5 --max-time 10 \
            "https://$addr/api/v1/system/services/status" 2>/dev/null || true)
          if [ -n "$status_resp" ]; then
            # Strip CR/LF that the CM API sometimes returns inside JSON values
            clean_resp=$${status_resp//$'\r'/}
            clean_resp=$${clean_resp//$'\n'/ }
            svc_status=$(echo "$clean_resp" | jq -r '.status' 2>/dev/null || echo "")

            if [ "$svc_status" = "started" ]; then
              consecutive_ok=$((consecutive_ok + 1))
              echo "[$addr] cluster-readiness OK ($consecutive_ok/$consecutive_required)"
              if [ "$consecutive_ok" -ge "$consecutive_required" ]; then
                return 0
              fi
            else
              if [ "$consecutive_ok" -gt 0 ]; then
                echo "[$addr] services flipped back to '$svc_status', resetting streak"
              else
                echo "[$addr] services status='$svc_status', waiting..."
              fi
              consecutive_ok=0
            fi
          else
            echo "[$addr] API unreachable, waiting..."
            consecutive_ok=0
          fi
          sleep "$poll_interval"
          elapsed=$((elapsed + poll_interval))
        done
        echo "ERROR: [$addr] did not become cluster-join ready within $${max_wait_seconds}s" >&2
        return 1
      }

      rc=0
      for addr in "$${addresses[@]}"; do
        echo "Probing CipherTrust Manager $addr for cluster-join readiness..."
        if ! check_node "$addr"; then
          rc=1
        fi
      done
      exit "$rc"
    EOT
  }
}

resource "null_resource" "cluster_init" {
  count = length(var.nodes) > 1 ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.cluster_init_commands
    # Using env vars for credentials instead of template vars for security reasons
    environment = {
      CM_USER     = nonsensitive(var.credentials.user)
      CM_PASSWORD = nonsensitive(var.credentials.password)
    }
  }
  triggers = {
    content = local.cluster_init_commands
  }
  depends_on = [
    null_resource.cluster_join_readiness
  ]
}

resource "ciphertrust_cluster" "cluster" {
  count = length(var.nodes) > 1 ? 1 : 0
  dynamic "node" {
    for_each = { for index, instance in var.nodes : index => instance }
    content {
      host           = node.value.host
      public_address = node.value.public_address
      original       = node.value.host == var.nodes[0].host && node.value.public_address == var.nodes[0].public_address
    }
  }
  depends_on = [
    null_resource.cluster_init
  ]
}

resource "null_resource" "ddc_active_node_setup" {
  count = var.ddc_node_setup.enabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.ddc_active_node_commands
    # Using env vars for credentials instead of template vars for security reasons
    environment = {
      CM_USER     = nonsensitive(var.credentials.user)
      CM_PASSWORD = nonsensitive(var.credentials.password)
    }
  }
  triggers = {
    content = local.ddc_active_node_commands
  }
  depends_on = [
    ciphertrust_cluster.cluster
  ]
}
