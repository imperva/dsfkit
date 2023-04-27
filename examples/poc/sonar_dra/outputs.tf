output "admin_server_url" {
  value = module.dra_admin.url
}


output "dra_analytics" {
   sensitive = true
   value = {
   for idx, val in module.analitycs_server_group : "analytics-${idx}" =>
    {
      public_ip   = try(val.analytics_public_ip, null)
      private_ip   = try(val.analytics_private_ip, null)
      archiver_user   = try(val.archiver_user, null)
      archiver_password   = try(val.archiver_password, null)
    }
   }
}

output "dra_analytics_incoming_folder_path" {
  value = "/opt/itpba/incoming"
}
