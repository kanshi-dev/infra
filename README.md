# Kanshi Infrastructure Deployment

This repository contains the Terraform infrastructure for deploying the Kanshi monitoring stack and its remote agents on AWS.

For the canonical self-hosted release stack, copy `.env.example` to `.env`, replace every placeholder, and run `docker compose up -d`. See the [v1 quickstart](https://github.com/kanshi-dev/core/blob/main/QUICKSTART.md).

Kanshi follows semantic versioning from `v1.0.0`. Bug fixes ship in `v1.0.x`, features wait for the next minor release, and breaking changes wait for the next major release. Release notes are generated from merged pull requests. Use the component repositories for support and private security reports. The latest `v1.0.x` release is supported.

## Architecture Overview

The deployment consists of two main components:

1.  **Kanshi Server**: A `t3.small` x86_64 EC2 instance running the core monitoring services via Docker Compose:
    *   **TimescaleDB**: Database for storing metrics.
    *   **Core API**: The central processing unit of Kanshi.
    *   **Dashboard**: Web interface for visualizing metrics.
2.  **Kanshi Agents**: Multiple EC2 instances (Ubuntu/Amazon Linux, x86_64/ARM64) running the Kanshi agent, which reports metrics back to the Server.

All resources are deployed within a dedicated VPC with public subnets across two availability zones.

## Project Structure

*   `main.tf`: Defines the core infrastructure (VPC, Security Groups, and EC2 instances).
*   `variables.tf`: Configuration variables for ports, environment, and security rules.
*   `outputs.tf`: Terraform outputs for the deployment.
*   `modules/`: Contains reusable modules for `vpc` and `ec2`.
*   `scripts/`:
    *   `server_user_data.sh.tftpl`: Server provisioning.
    *   `agent_user_data.sh.tftpl`: Agent installation through the verified release installer.

## Prerequisites

*   [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
*   [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials.

## Deployment Instructions

1.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

2.  **Review the Plan**:
    ```bash
    terraform plan
    ```

3.  **Apply the Configuration**:
    ```bash
    terraform apply
    ```

Terraform generates the database, ingest, and dashboard keys. Retrieve the dashboard key after apply:

```bash
terraform output -raw dashboard_key
```

State is local. Keep `terraform.tfstate` private and do not use this configuration as a shared production backend without migrating state to an encrypted remote backend with locking.

## Security Configuration

The security groups are configured with the following ingress rules by default:

### Server (kanshi-server-sg)
| Port | Protocol | Description |
| :--- | :--- | :--- |
| 80 | TCP | Dashboard |
Core REST is reachable only through the dashboard proxy. Core gRPC accepts traffic only from instances in the agent security group. Neither server nor agents expose SSH.

*Note: Egress traffic is allowed for all protocols to any destination (0.0.0.0/0).*

## Outputs

After a successful deployment, Terraform will output:
*   `server_public_ip`: The public IP address of the Kanshi Server.
*   `agent_public_ips`: A map of the public IP addresses of the Kanshi Agents.
*   `dashboard_url`: The URL to access the Kanshi Dashboard.
