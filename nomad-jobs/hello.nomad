job "hello" {
  datacenters = ["dc1"]
  type = "service"

  group "example" {
    network {
      port "http" {
        static = 8080
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo"
        args  = ["-text=Hello World"]
        port_map {
          http = 8080
        }
      }

      resources {
        network {
          mbits = 10
        }
      }
    }
  }
}
