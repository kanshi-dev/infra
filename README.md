# Kanshi infrastructure

Kanshi has two test paths:

- [Local demo](https://github.com/kanshi-dev/demo): pulls the stable release with Docker Compose.
- Terraform demo in this directory: creates a disposable AWS fleet with one full-stack server and three agents.

## AWS demo architecture

Terraform creates:

- A dedicated VPC with two public subnets
- One `t3.small` Ubuntu server running TimescaleDB, Core, Dashboard, OpenTelemetry Collector, and Go and Node.js sample services
- Three agents covering Ubuntu amd64, Ubuntu arm64, and Amazon Linux amd64
- One Alpine demo driver that creates the memory alert when missing and continuously generates checkout traffic
- Distributed traces, correlated logs, and signed alert delivery to a private webhook sink
- Generated database, ingest, and dashboard keys

Only dashboard port `80` is public. Core gRPC `50051` accepts traffic only from the agent security group. REST is available through the dashboard proxy. SSH is not exposed.

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

The server pulls the versioned public Core, Dashboard, and multi-architecture sample images from GHCR during first boot. Agents install from the checksum-verified release installer.

## Verify

```sh
curl "$(terraform output -raw dashboard_url)"
```

After signing in, verify:

- Agents shows all three hosts online with CPU and memory data.
- Services shows `checkout-api` and `payments-api`.
- Traces shows fresh checkout traces spanning both services.
- Opening a trace shows correlated logs.
- Alerts shows the enabled `Demo high memory` rule and a delivered firing event after Agent metrics arrive.

The demo driver is fetched from an immutable demo revision. It creates a checkout every 30 seconds and does not duplicate the alert rule after a restart. The alert evaluator runs every 10 seconds and triggers when real Agent memory usage exceeds 1 percent. Sample services, Collector receivers, and the webhook sink stay private inside the server's Docker network.

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
- `alert-sink.py`: private signed-webhook receiver
- `main.tf`, `variables.tf`, `output.tf`: root Terraform configuration
- `modules/vpc`: VPC resources
- `modules/ec2`: hardened EC2 instance module
- `scripts/server_user_data.sh.tftpl`: server bootstrap
- `scripts/agent_user_data.sh.tftpl`: agent bootstrap
