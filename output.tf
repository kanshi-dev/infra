output "server_public_ip" {
  value = module.kanshi_server.public_ip
}

output "dashboard_url" {
  value = "http://${module.kanshi_server.public_ip}"
}

output "agent_public_ips" {
  value = { for k, v in module.kanshi_agent : k => v.public_ip }
}

output "dashboard_key" {
  description = "Shared key used to open the dashboard"
  value       = random_password.dashboard_key.result
  sensitive   = true
}

output "dashboard_key_command" {
  description = "Command to reveal the dashboard login key"
  value       = "terraform output -raw dashboard_key"
}
