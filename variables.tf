variable "server_ingress_rules" {
  description = "List of ingress rules for the Kanshi server"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Dashboard"
    },
  ]
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "core_version" {
  description = "Core container image version"
  type        = string
  default     = "1.0.0"
}

variable "dashboard_version" {
  description = "Dashboard container image version"
  type        = string
  default     = "1.0.0"
}

variable "agent_version" {
  description = "Agent release version"
  type        = string
  default     = "v1.0.0"
}

variable "agents" {
  description = "Configuration for Kanshi agents"
  type = map(object({
    instance_type = string
    os            = string # e.g., "ubuntu", "amazon-linux"
    arch          = string # e.g., "amd64", "arm64"
  }))
  default = {
    "agent-ubuntu-arm" = {
      instance_type = "t4g.micro"
      os            = "ubuntu"
      arch          = "arm64"
    },
    "agent-ubuntu-amd" = {
      instance_type = "t3.micro"
      os            = "ubuntu"
      arch          = "amd64"
    },
    "agent-al2023-amd" = {
      instance_type = "t3.micro"
      os            = "amazon-linux"
      arch          = "amd64"
    }
  }
}
