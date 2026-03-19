provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source      = "./modules/vpc"
  environment = var.environment
}

# Security group for the Server (Dashboard, Core, DB)
resource "aws_security_group" "server_sg" {
  name        = "kanshi-server-sg"
  description = "Allow web and gRPC traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name        = "kanshi-server-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "server_ingress" {
  for_each = { for idx, rule in var.server_ingress_rules : idx => rule }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.server_sg.id
}

resource "aws_security_group_rule" "server_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server_sg.id
}

# Security group for the Agent
resource "aws_security_group" "agent_sg" {
  name        = "kanshi-agent-sg"
  description = "Allow SSH"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name        = "kanshi-agent-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "agent_ingress" {
  for_each = { for idx, rule in var.agent_ingress_rules : idx => rule }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.agent_sg.id
}

resource "aws_security_group_rule" "agent_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.agent_sg.id
}

# Ubuntu 24.04 AMI for x86_64
data "aws_ami" "ubuntu_x86" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Ubuntu 24.04 AMI for ARM64
data "aws_ami" "ubuntu_arm" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }
}

# Amazon Linux 2023 AMI for x86_64
data "aws_ami" "al2023_x86" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# Amazon Linux 2023 AMI for ARM64
data "aws_ami" "al2023_arm" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-arm64"]
  }
}

locals {
  ami_map = {
    "ubuntu-amd64"       = data.aws_ami.ubuntu_x86.id
    "ubuntu-arm64"       = data.aws_ami.ubuntu_arm.id
    "amazon-linux-amd64" = data.aws_ami.al2023_x86.id
    "amazon-linux-arm64" = data.aws_ami.al2023_arm.id
  }
}

module "kanshi_server" {
  source             = "./modules/ec2"
  instance_name      = "kanshi-server"
  instance_type      = "t3.small"
  ami_id             = data.aws_ami.ubuntu_x86.id
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [aws_security_group.server_sg.id]
  environment        = var.environment

  user_data          = templatefile("${path.module}/scripts/server_user_data.sh.tftpl", {
    env_file_content       = fileexists("${path.module}/scripts/.env") ? file("${path.module}/scripts/.env") : file("${path.module}/scripts/.env.example")
  })
}

module "kanshi_agent" {
  for_each           = var.agents
  source             = "./modules/ec2"
  instance_name      = each.key
  instance_type      = each.value.instance_type
  ami_id             = local.ami_map["${each.value.os}-${each.value.arch}"]
  subnet_id          = module.vpc.public_subnet_ids[1]
  security_group_ids = [aws_security_group.agent_sg.id]
  environment        = var.environment

  user_data = templatefile("${path.module}/scripts/agent_user_data.sh.tftpl", {
    kanshi_server_private_ip = module.kanshi_server.private_ip
    arch                     = each.value.arch
  })
}
