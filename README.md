# Nomad Demo — Infrastructure & Deployment

This repository contains a small, repeatable demo to provision a Nomad cluster (bastion, nomad server, nomad client), run a sample web app, and verify everything works. The infrastructure is created with Terraform and the nodes bootstrap Nomad via `user_data` scripts.

> **Goal:** provide a reproducible, disposable test environment you can `terraform apply` / `terraform destroy` many times during development.

---

## Repository link

Place your code in a public Git repository and update the URL below so reviewers can clone and run it:

https://github.com/siddharth5815/nomad-terraform.git

---

## What’s included

* Terraform code to create:

  * VPC, public subnet, IGW, route table
  * Security Groups (bastion, nomad server, nomad client)
  * EC2 instances: Bastion, Nomad Server, Nomad Client
  * AWS Key Pair (uploads your local `.pub` file)
* `user_data/nomad_server.sh` — boots Nomad server and Docker
* `user_data/nomad_client.sh` — boots Nomad client and Docker (optional)
* `jobs/web.nomad` — small example job to run an nginx web server
* `README.md` — this file with architecture, deploy steps, access instructions, and credentials

---

## Architecture

* **Single VPC, single public subnet** — keeps demo simple and easy to destroy/recreate.
* **Bastion host** — a small instance with a public IP used as a jump host so the Nomad server can remain private if desired.
* **Nomad server (bootstrap\_expect = 1)** — single-server bootstrap for quick testing. For production this should be 3+ servers and use TLS and ACLs.
* **Nomad client** — runs Docker workloads (the sample web app uses Docker).
* **Key pair management** — Terraform uploads your *local public key* (path configured via variable). This avoids storing private keys or credentials in the repo.
* **Security Groups** — permissive by default for testing (SSH open). Tighten them for real environments.
* **Idempotent IaC** — everything is created via Terraform so `destroy` → `apply` yields a fresh, reproducible environment.

Design decisions favor reproducibility and low friction for reviewers, not production-hardening. Comments in the Terraform files point where to harden the setup.

---

## Prerequisites (what you need locally)

* An AWS account with permissions to create EC2, VPC, Security Groups, and Key Pairs.
* AWS CLI configured (or environment variables): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, optionally `AWS_SESSION_TOKEN`.
* Terraform >= 1.2.0 installed.
* `ssh` installed locally and a private/public key pair (or willingness to generate one).
* `git` to clone and push the repo.


## Quick start — deploy (step-by-step)

1. **Clone the repo**

```bash
git clone https://github.com/siddharth5815/nomad-terraform.git
cd nomad-demo
```

2. **(Optional) Generate or ensure you have an SSH key**

> If you already have a key you want to use, skip these lines.

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/nomad-demo -N ""
# public key now at ~/.ssh/nomad-demo.pub
```

3. **Set variables (two options)**

Option A — edit `variables.tf` defaults (quick, local use): change `ssh_public_key_path` and `key_name` as needed.

Option B — create a `terraform.tfvars` file in the repo folder:

```hcl
region = "ap-south-1"
instance_type = "t3.micro"
ssh_public_key_path = "/Users/you/.ssh/nomad-demo.pub"
key_name = "nomad-demo"
```

4. **Initialize and apply**

```bash
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

Terraform outputs will show the public IPs for the bastion, client, and the nomad server public IP (if you used a public one). Example outputs are: `bastion_public_ip`, `client_public_ips`, `nomad_server_public_ip`.

5. **Confirm EC2s are up**

```bash
terraform output
```

---

## SSH shortcuts

Add this to your `~/.ssh/config` (replace paths and IPs with the values from `terraform output` or keep hostnames as below to use as a template):

```sshconfig
Host bastion
  HostName <BASTION_PUBLIC_IP>
  User ubuntu
  IdentityFile /path/to/your/nomad-demo

Host nomad-server
  HostName <NOMAD_PRIVATE_IP_OR_PUBLIC>
  User ubuntu
  IdentityFile /path/to/your/nomad-demo
  ProxyJump bastion

Host client
  HostName <CLIENT_PUBLIC_IP>
  User ubuntu
  IdentityFile /path/to/your/nomad-demo
  ProxyJump bastion
```

Then use `ssh bastion`, `ssh nomad-server`, or `ssh client`.

---

## How to access the Nomad UI and the sample app

### Nomad UI

**Direct (public IP)** — if `nomad_server_public_ip` is public and port 4646 is reachable:

```
http://$(terraform output -raw nomad_server_public_ip):4646
```

**Local tunnel (if server is private)** — use SSH port forwarding through the bastion (run this on your laptop):

```bash
ssh -i /path/to/nomad-demo -L 4646:<NOMAD_PRIVATE_IP>:4646 -J ubuntu@<BASTION_PUBLIC_IP> ubuntu@<BASTION_PUBLIC_IP> -N
# Then open http://localhost:4646 in your browser
```

> Replace `<NOMAD_PRIVATE_IP>` and `<BASTION_PUBLIC_IP>` with values from `terraform output`.

### Deploy and access the sample web app (example)

1. Copy the example job to the server or create it there. `jobs/web.nomad` contains a tiny nginx job listening on port 8080.

`jobs/web.nomad` (example):

```hcl
job "web" {
  datacenters = ["dc1"]
  type = "service"

  group "web-group" {
    count = 1

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:latest"
        ports = ["http"]
      }

      resources {
        cpu    = 200
        memory = 128
        network {
          port "http" {
            static = 8080
          }
        }
      }
    }
  }
}
```

2. Run the job on the Nomad server (or any machine with Nomad CLI and access):

```bash
ssh nomad-server
# on the server
nomad job run /path/to/jobs/web.nomad
nomad job status web
```

3. The job binds port `8080` on the client node. Visit:

```
http://<CLIENT_PUBLIC_IP>:8080
```

If the client is private, use the bastion to tunnel the port similarly to the Nomad UI example.

---

## Credentials required to test deliverables

* **SSH**: private key file (path you provided) and the user `ubuntu`.

  * Example: `/Users/you/.ssh/nomad-demo` and `ssh -i /Users/you/.ssh/nomad-demo ubuntu@<bastion-ip>`
* **Nomad UI**: no credentials for this demo (default). If you enable ACLs, credentials will be in the repo docs.
* **Sample app**: none — it’s a public nginx welcome page on port `8080` used for smoke testing.

> Note: For security, do not commit private keys or AWS secrets into the repository. Keep only public keys and configuration code.

---

## Cleanup

To remove everything created by Terraform:

```bash
terraform destroy -auto-approve
```

This will tear down instances, VPC, and other resources created by the demo. If you let Terraform create the AWS Key Pair, destroy will remove it as well.

---

## Troubleshooting (quick hits)

* **ImportKeyPair MissingParameter** — Terraform can’t find/read the `.pub` file. Check path and permissions:

```bash
ls -l /path/to/nomad-demo.pub
cat /path/to/nomad-demo.pub
```

* **SSH permission denied** — ensure the private key is `chmod 600` and you’re using the right username (`ubuntu`).

* **Nomad nodes not joining** — check security groups for ports 4646/4647/4648 and confirm private IPs in `advertise` settings; check logs with `journalctl -u nomad`.

---
