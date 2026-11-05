# AI-Driven Hybrid Cloud Migration & Incident Response Pipeline

## Project Overview
This repository demonstrates an end-to-end enterprise cloud migration and security modernization strategy. Built entirely with Infrastructure as Code (Terraform), it simulates the transition from a traditional "Lift & Shift" architecture to a secure, Zero Trust cloud environment.

## Phase 1: Network Foundation & Lift and Shift (Completed)
- Provisioned a custom AWS Virtual Private Cloud (VPC).
- Segmented network architecture into Public and Private Subnets.
- Configured Internet Gateways and Route Tables for precise traffic control.
- Deployed an EC2 instance dynamically running a Python Flask application using `user_data` bootstrapping.
- Implemented stateful Virtual Firewalls (Security Groups).

## Phase 2 & 3: Coming Soon...
- Zero Trust Implementation & Network Isolation
- Application Load Balancer Integration
- AI-Driven Incident Response Log Analysis (CloudTrail + LLM)

## Tech Stack
**Cloud Provider:** AWS (Amazon Web Services)
**IaC:** Terraform
**Compute & Network:** VPC, EC2, Subnets, Security Groups
**Language:** Python (Flask)