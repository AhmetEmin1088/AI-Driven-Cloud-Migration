# AI-Driven Hybrid Cloud Migration & Incident Response Pipeline

## Project Overview
This repository demonstrates an end-to-end enterprise cloud migration and security modernization strategy. Built entirely with Infrastructure as Code (Terraform), it simulates the transition from a traditional "Lift & Shift" architecture to a secure, Zero Trust cloud environment.

## Phase 1: Network Foundation & Lift and Shift
- Provisioned a custom AWS Virtual Private Cloud (VPC).
- Segmented network architecture into Public and Private Subnets.
- Configured Internet Gateways and Route Tables for precise traffic control.
- Deployed an EC2 instance dynamically running a Python Flask application using `user_data` bootstrapping.
- Implemented stateful Virtual Firewalls (Security Groups).

## Phase 2: Zero Trust Isolation & High Availability
- Expanded network architecture with a second Public Subnet across multiple Availability Zones for High Availability.
- Deployed an AWS Application Load Balancer (ALB) to act as the single internet-facing reverse proxy.
- Enforced Zero Trust network boundaries by stripping public internet ingress (`0.0.0.0/0`) from the application server.
- Configured strict Security Group referencing, ensuring the backend EC2 instance silently drops all traffic not explicitly originating from the ALB.

## Phase 3: AI-Driven Incident Response
- Activated AWS CloudTrail for comprehensive API and account auditing.
- Developed a Python-based AI Security Analyst (`incident_responder.py`).
- Integrated the `google-genai` SDK and the Gemini 2.0 Flash model.
- Successfully parsed live CloudTrail JSON logs and generated a professional, CISO-ready Incident Response report detecting Root account usage and perimeter exposure.

## How to Run This Project
1. Configure AWS CLI with an IAM user (`aws configure`).
2. Run `terraform init`, `plan`, and `apply` to build the infrastructure.
3. Create a Python virtual environment: `python -m venv venv && source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Export your Gemini API key: `export GEMINI_API_KEY="your_key"`
6. Run the AI Analyst: `python incident_responder.py`
7. Tear down: `terraform destroy`

## Tech Stack
**Cloud Provider:** AWS (Amazon Web Services)
**IaC:** Terraform
**Compute & Network:** VPC, EC2, Subnets, Security Groups, Application Load Balancer (ALB)
**Language:** Python (Flask)
