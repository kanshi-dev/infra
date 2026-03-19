output "server_public_ip" {
  value = module.kanshi_server.public_ip
}

output "dashboard_url" {
  value = "http://${module.kanshi_server.public_ip}"
}

output "agent_public_ip" {
  value = module.kanshi_agent.public_ip
}
