# Kanshi Infrastructure Deployment

This repository contains the Terraform infrastructure for deploying the Kanshi monitoring stack and its remote agents on AWS.

## Architecture Overview

The deployment consists of two main components:

1.  **Kanshi Server**: A `t3.small` x86_64 EC2 instance running the core monitoring services via Docker Compose:
    *   **TimescaleDB**: Database for storing metrics.
    *   **Core API**: The central processing unit of Kanshi.
    *   **Dashboard**: Web interface for visualizing metrics.
2.  **Kanshi Agent**: A `t4g.micro` ARM64 EC2 instance running the Kanshi agent, which reports metrics back to the Server.

All resources are deployed within a dedicated VPC with public subnets across two availability zones.

## Project Structure

*   `main.tf`: Defines the core infrastructure (VPC, Security Groups, and EC2 instances).
*   `variables.tf`: Configuration variables for ports, environment, and security rules.
*   `modules/`: Contains reusable modules for `vpc` and `ec2`.
*   `scripts/`:
    *   `docker-compose.yml`: Docker configuration for the Server services.
    *   `core-schema.sql`: Initial database schema.
    *   `.env.example`: Environment variables for the database.
    *   `server_user_data.sh.tftpl`: Provisioning script for the Server.
    *   `agent_user_data.sh.tftpl`: Provisioning script for the Agent.

## Prerequisites

*   [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
*   [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials.

## Deployment Instructions

1.  **Environment Setup**:
    Copy the example environment file and update it with your desired database credentials:
    ```bash
    cp scripts/.env.example scripts/.env
    ```

2.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

3.  **Review the Plan**:
    ```bash
    terraform plan
    ```

4.  **Apply the Configuration**:
    ```bash
    terraform apply
    ```

The deployment will automatically use the values from `scripts/.env` for the Kanshi server's environment.

## Security Configuration

The security groups are configured with the following ingress rules by default:

### Server (kanshi-server-sg)
| Port | Protocol | Description |
| :--- | :--- | :--- |
| 80 | TCP | Dashboard |
| 8080 | TCP | Core API |
| 50051 | TCP | Core gRPC (used by agents) |
| 22 | TCP | SSH |

### Agent (kanshi-agent-sg)
| Port | Protocol | Description |
| :--- | :--- | :--- |
| 22 | TCP | SSH |

*Note: Egress traffic is allowed for all protocols to any destination (0.0.0.0/0).*

## Outputs

After a successful deployment, Terraform will output:
*   `server_public_ip`: The public IP address of the Kanshi Server.
*   `agent_public_ip`: The public IP address of the Kanshi Agent.
*   `dashboard_url`: The URL to access the Kanshi Dashboard.
