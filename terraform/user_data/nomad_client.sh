client {
  enabled = true
  servers = [""] # Private IP
}

# Enable Docker driver
plugin "docker" {
  config {
    enabled = true
  }
}
