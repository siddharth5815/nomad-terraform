# Create key pair from provided public key
resource "aws_key_pair" "deployer" {
  key_name   = "nomad-demo-key"
  public_key = var.ssh_public_key
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = [var.ubuntu_ami_name]
  }
}

# Bastion host for SSH jumpbox
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  tags = { Name = "nomad-bastion" }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y htop
              EOF
}

# Nomad server - user_data read via file() (server determines own IP using instance metadata)
resource "aws_instance" "nomad_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  # key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.nomad_server_sg.id]
  tags = { Name = "nomad-server" }

  # Add this line to specify your SSH key
  key_name = "nomad-demo"

  # IMPORTANT: use file() so Terraform doesn't need to interpolate instance attributes
  user_data = file("${path.module}/user_data/nomad_server.sh")
}
