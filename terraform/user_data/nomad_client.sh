client {
  enabled = true
  servers = ["10.0.1.57"]  # replace with your Nomad server private IP
}

# Enable Docker driver
plugin "docker" {
  config {
    enabled = true
  }
}
