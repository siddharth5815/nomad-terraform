resource "aws_security_group" "bastion_sg" {
  name        = "nomad-bastion-sg"
  description = "Allow SSH from admin"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
    description = "SSH from admin"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nomad_server_sg" {
  name        = "nomad-server-sg"
  description = "Nomad server SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Nomad HTTP/UI (VPC)"
  }
  ingress {
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Nomad RPC (VPC)"
  }
  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Nomad serf tcp"
  }
  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Nomad serf udp"
  }

  # Allow bastion to SSH to server if needed
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.bastion_sg.id]
    description      = "SSH from bastion"
  }
  ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["13.203.28.218/32"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nomad_client_sg" {
  name        = "nomad-client-sg"
  description = "Nomad client SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Nomad RPC to servers"
  }

  # For demo, allow app port 8080 from anywhere (tighten in prod)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Demo app port"
  }

  # Allow bastion to SSH into clients
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "SSH from bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
