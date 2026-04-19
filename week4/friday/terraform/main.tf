terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# --- Data source: fetch latest Ubuntu 22.04 AMI dynamically ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Networking: use the default VPC and subnet ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security group: SSH from your IP only, app ports open ---
resource "aws_security_group" "kijanikiosk" {
  name        = "kijanikiosk-${var.environment}"
  description = "Security group for KijaniKiosk staging servers"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from operator IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "kijanikiosk-${var.environment}"
    Environment = var.environment
    Project     = "kijanikiosk"
  }
}

# --- Module call: for_each creates api, payments, logs servers ---
module "app_server" {
  source = "./modules/app_server"

  for_each = var.servers

  server_name        = each.value.name
  instance_type      = var.instance_type
  ami_id             = data.aws_ami.ubuntu.id
  key_name           = var.key_name
  subnet_id          = data.aws_subnets.default.ids[0]
  security_group_ids = [aws_security_group.kijanikiosk.id]
  environment        = var.environment
}
