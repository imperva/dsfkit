output "ready" {
  description = "Indicates when cluster is setup"
  value       = "ready"
  depends_on = [
    null_resource.cluster_setup
  ]
}