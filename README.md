# Smart Token Labs - Terraform

![Logo](https://cdn-images-1.medium.com/max/1320/1*sIaWPuUDRyDZRnnWdgKZ2g@2x.png)

## Description

Repository for the Terraform code of the Smart Token Labs challenge.

## Architecture

There are two different environments (stage and prod), each with it's own full stack using the following AWS services:

- ECS Fargate for the API
- ECR for hosting the Docker images
- RDS PostgreSQL for the DB
- ALB for proxying requests
- EC2 for the bastion host
- CloudWatch for monitoring and logging
- IAM for handling roles and permissions
- Route53 for managing DNS zones and records

## Networking

1. Each environment has its own isolated VPC sized /16:

| Environment |  Region   | CIDR Block   |
| ----------- | --------- | ------------ |
|   stage     | us-east-1 | 10.0.0.0/16  |
|   prod      | us-east-1 | 10.1.0.0/16  |

2. Where each VPC is divided into several /19 blocks for differents subnets:

| Subnet   | Region    | CIDR Block        |
| -------- | --------- | ----------------- |
| private  | us-east-1 | 10.{0/1}.0.0/19   |
| public   | us-east-1 | 10.{0/1}.96.0/19  |
| database | us-east-1 | 10.{0/1}.192.0/19 |

3. Each block then is divided into /24 subnets between 3 different availability zones:

| AZ | Description | CIDR Block                 |
| -- | ----------- | -------------------------- |
| 1  | us-east-1a  | 10.{0/1}.{1/101/202}.0/24  |
| 2  | us-east-1b  | 10.{0/1}.{2/102/202}.0/24  |
| 3  | us-east-1c  | 10.{0/1}.{3/103/203}.0/24  |

## Requirements

- [Terraform 1.0.x](https://www.terraform.io)
- [Terraform Cloud](https://cloud.hashicorp.com/products/terraform) access
- [tfenv](https://github.com/kamatama41/tfenv) (optional, for managing Terraform versions)-

## Deploy

Terraform Cloud is used for storing the statefiles and managing changes to the resources: two different workspaces are configured, one for each environment with it's own set of variables.

CI/CD is configured using Terraform Cloud connected to GitHub, so automatic plans and applys are triggered automatically after every push to the `main` branch of this repository.

Additionally, the plan can be executed locally for faster debugging by using the Terraform CLI connected to Terraform Cloud, instructions [here](https://developer.hashicorp.com/terraform/cli/cloud).

## Roadmap

Future improvements that could be done:

- Encrypt DB credentials using sops, SSM or HashiCorp Vault to avoid having them in plain text in the repository
- Configure [pre-commit](https://pre-commit.com) for running pre-commit hooks with linters and validators
- Use Aurora Serverless for avoid having a DB running 24/7 in the case of stage environment
- Evaluate migration of ECS Fargate to EKS to have a more robust orchestration system if needs arise
