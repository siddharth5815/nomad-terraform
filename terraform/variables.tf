variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "client_count" {
  description = "Number of Nomad clients"
  type        = number
  default     = 1
}

variable "ssh_public_key" {
  description = "SSH public key contents (for EC2 key pair)"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to bastion (set to your IP /32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_key_name" {
  type        = string
  default     = "nomad-demo"
}

variable "ubuntu_ami_name" {
  description = "AMI name pattern for Ubuntu"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}
