# AI-Driven Hybrid Cloud Migration & Incident Response Pipeline

## Project Overview
This repository demonstrates an end-to-end enterprise cloud migration and security modernization strategy. Built entirely with Infrastructure as Code (Terraform), it simulates the transition from a traditional "Lift & Shift" architecture to a secure, Zero Trust cloud environment.

## Phase 1: Network Foundation & Lift and Shift (Completed)
- Provisioned a custom AWS Virtual Private Cloud (VPC).
- Segmented network architecture into Public and Private Subnets.
- Configured Internet Gateways and Route Tables for precise traffic control.
- Deployed an EC2 instance dynamically running a Python Flask application using `user_data` bootstrapping.
- Implemented stateful Virtual Firewalls (Security Groups).

## Phase 2: Zero Trust Isolation & High Availability (Completed)
- Expanded network architecture with a second Public Subnet across multiple Availability Zones for High Availability.
- Deployed an AWS Application Load Balancer (ALB) to act as the single internet-facing reverse proxy.
- Enforced Zero Trust network boundaries by stripping public internet ingress (`0.0.0.0/0`) from the application server.
- Configured strict Security Group referencing, ensuring the backend EC2 instance silently drops all traffic not explicitly originating from the ALB.

## Phase 3: Coming Soon...
- AI-Driven Incident Response Log Analysis (AWS CloudTrail + LLM Integration)
- Automated threat detection and AI response generation

## Tech Stack
**Cloud Provider:** AWS (Amazon Web Services)
**IaC:** Terraform
**Compute & Network:** VPC, EC2, Subnets, Security Groups, Application Load Balancer (ALB)
**Language:** Python (Flask)