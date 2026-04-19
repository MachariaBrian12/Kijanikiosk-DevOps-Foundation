output "api_server_ip" {
  description = "Public IP of the api server"
  value       = module.app_server["api"].public_ip
}

output "payments_server_ip" {
  description = "Public IP of the payments server"
  value       = module.app_server["payments"].public_ip
}

output "logs_server_ip" {
  description = "Public IP of the logs server"
  value       = module.app_server["logs"].public_ip
}

output "ssh_commands" {
  description = "SSH commands for all three servers"
  value = {
    api      = module.app_server["api"].ssh_command
    payments = module.app_server["payments"].ssh_command
    logs     = module.app_server["logs"].ssh_command
  }
}
