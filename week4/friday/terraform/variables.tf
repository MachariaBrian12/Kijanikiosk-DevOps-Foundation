variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for all servers"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the AWS key pair to use for SSH access"
  type        = string
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
  default     = "staging"
}

variable "allowed_ssh_cidr" {
  description = "Your IP in CIDR notation allowed to SSH into the servers e.g. 1.2.3.4/32"
  type        = string
}

variable "servers" {
  description = "Map of server definitions to create with for_each"
  type = map(object({
    name = string
  }))
  default = {
    api = {
      name = "kk-api"
    }
    payments = {
      name = "kk-payments"
    }
    logs = {
      name = "kk-logs"
    }
  }
}
