### Databricks AWS Deployment via Terraform IaC Automation (CloudShell-Based)

----------

## Overview

This project automates deployment of a Databricks workspace on AWS using:  
  
- Terraform  
- AWS PrivateLink  
- Secrets Manager  
- CloudShell-optimized execution  
  
It is designed to minimize manual setup and eliminate common deployment issues.

----------

## Design Principles

- No hardcoded environment values  
- Dynamic resource generation  
- CloudShell-first execution model  
- Minimal dependencies  
- Secure secret handling

----------

## Why CloudShell

This project is designed to run in AWS CloudShell.  
  
Reasons:  
- Preconfigured AWS credentials  
- No local setup required  
- Fewer IAM permission issues  
- Faster iteration and testing  
- Built-in access to AWS CLI  
  
Running on EC2 or local machines is not recommended unless fully configured.

----------

## Prerequisites

- AWS account with permissions:  
 - EC2 (VPC, subnets, endpoints)  
 - Secrets Manager  
- Databricks workspace already created  
- Terraform installed (optional wrapper supported)  
- jq and curl available

----------

## Execution Steps

chmod  +x *.sh  
  
./00_prereqs_check.sh  
./01_setup_cloudshell.sh  
./02_cleanup_and_prepare.sh  
./03_network_bootstrap.sh  
./04_databricks_manual_step.sh  
./05_databricks_secret_and_validation.sh  
./06_generate_tfvars.sh  
./07_terraform_deploy.sh  
./08_cluster_validation.sh  
./09_optional_spark_validation.sh

----------

## What This Validates

- AWS networking (PrivateLink)  
- IAM cross-account roles  
- Databricks workspace connectivity  
- Cluster lifecycle (start → run → terminate)  
- Optional Spark execution

----------

## Limitations

- Requires Databricks workspace to already exist  
- Requires IAM permissions to create AWS resources  
- Not fully autonomous (Databricks UI step required)  
- CIDR ranges are dynamically generated but may conflict in restricted environments
