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
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Core API"
    },
    {
      from_port   = 50051
      to_port     = 50051
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Core gRPC"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH"
    }
  ]
}

variable "agent_ingress_rules" {
  description = "List of ingress rules for the Kanshi agent"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH"
    }
  ]
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
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
