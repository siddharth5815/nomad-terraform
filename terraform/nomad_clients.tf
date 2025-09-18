resource "aws_instance" "nomad_client" {
  count                       = var.client_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.nomad_client_sg.id]

  tags = {
    Name = "nomad-client-${count.index + 1}"
  }

  user_data = templatefile("${path.module}/user_data/nomad_client.sh", {
    nomad_server_ip = aws_instance.nomad_server.private_ip
  })
}
