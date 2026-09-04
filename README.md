# Kanshi infrastructure

Kanshi has two test paths:

- [Local demo](https://github.com/kanshi-dev/demo): pulls the stable release with Docker Compose.
- Terraform demo in this directory: creates a disposable AWS fleet with one full-stack server and four agents.

## AWS demo architecture

Terraform creates:

- A dedicated VPC with two public subnets
- One `t3.small` Ubuntu server running TimescaleDB, Core, Dashboard, OpenTelemetry Collector, and Go and Node.js sample services
- Four agents: one on the application server plus Ubuntu amd64, Ubuntu arm64, and Amazon Linux amd64 hosts
- One Alpine demo driver that creates the memory alert when missing and continuously generates checkout traffic
- Distributed traces, correlated logs, and signed alert delivery to a private webhook sink
- Generated database, ingest, and dashboard keys

Only dashboard port `80` is public. Core gRPC `50051` accepts traffic only from the agent security group. REST is available through the dashboard proxy. SSH is not exposed.
Checkout pprof port `6060` is bound only to server loopback. The host Agent discovers the approved `checkout` target across `6059-6061`; no profiling port is reachable from the VPC or internet.

## Requirements

- Terraform
- AWS credentials with permission to create the declared VPC, EC2, and security-group resources

## Deploy

```sh
git clone https://github.com/kanshi-dev/infra.git
cd infra
terraform init
terraform plan
terraform apply
```

Get the dashboard URL and login key:

```sh
terraform output -raw dashboard_url
terraform output -raw dashboard_key
```

After apply, Terraform also prints the command needed to reveal the sensitive dashboard key.

The server pulls the versioned public Core and Dashboard images plus the latest multi-architecture demo images from GHCR during first boot. Agents install from the checksum-verified release installer.

## Verify

```sh
curl "$(terraform output -raw dashboard_url)"
```

After signing in, verify:

- Fleet shows all four hosts online with CPU, memory, disk, and network history.
- The `kanshi-server` Agent shows current process telemetry.
- The `kanshi-server` Agent Profiles tab discovers `checkout` and completes a CPU capture.
- Services shows `checkout-api` and `payments-api`.
- Service and trace host links navigate to the `kanshi-server` Agent through `host.name`.
- Traces shows fresh checkout traces spanning both services.
- Opening a trace shows correlated logs.
- Alerts shows the enabled `Demo high memory` rule and a delivered firing event after Agent metrics arrive.
- The Dashboard works at desktop and mobile widths in both Light and Dark themes.

The Demo Driver image receives alert webhooks, creates a checkout every 30 seconds, and does not duplicate the alert rule after a restart. The alert evaluator runs every 10 seconds and triggers when real Agent memory usage exceeds 1 percent. Sample services, Collector receivers, and the Demo Driver stay private inside the server's Docker network.

## Destroy

This environment creates billable AWS resources. Remove it when testing is complete:

```sh
terraform destroy
```

## State and security

State is local and contains generated secrets. Keep `terraform.tfstate` private. Local state is appropriate for this disposable single-operator demo; migrate to an encrypted remote backend with locking before shared or production use.

The EC2 root volumes are encrypted and require IMDSv2. Do not widen the security groups to expose `22`, `8080`, or `50051` publicly.

## Repository layout

- `docker-compose.yaml`: server stack
- `otel-collector.yaml`: authenticated trace and log pipeline
- `main.tf`, `variables.tf`, `output.tf`: root Terraform configuration
- `modules/vpc`: VPC resources
- `modules/ec2`: hardened EC2 instance module
- `scripts/server_user_data.sh.tftpl`: server bootstrap
- `scripts/agent_user_data.sh.tftpl`: agent bootstrap
