# AWS Cloud Engineering Portfolio

A collection of hands-on AWS infrastructure projects demonstrating practical skills in cloud security, compute, storage, and networking. Each project is independently documented with architecture diagrams, implementation notes, reusable scripts, and learnings.

---

## Projects

### 1. [AWS WAF — IP-Based Web Traffic Filtering](./aws-waf-web-traffic-filtering/)

**Domain:** Cloud Security | Networking

Implemented a Web Application Firewall to protect a load-balanced EC2 web application from unauthorized access using AWS WAF IP Sets and Web ACLs. The solution filters traffic at the application layer before it reaches the ALB, demonstrating defense-in-depth principles.

**Key skills:** AWS WAF, Application Load Balancer, EC2, Security Groups, IP-based access control

---

### 2. [EBS Multi-Attach — Shared Block Storage Architecture](./aws-ebs-multi-attach/)

**Domain:** Storage | High Availability

Configured a shared Amazon EBS io1 volume attached to two EC2 instances simultaneously using the Multi-Attach feature. Implemented safe access patterns (one read-write writer, one read-only reader) to prevent filesystem corruption while enabling real-time shared data access.

**Key skills:** EBS Multi-Attach, EC2, Linux filesystem management (ext4), block storage design

---

## Skills Demonstrated

| Category | Skills |
|---|---|
| **Compute** | EC2 instance provisioning, user data scripts, instance types |
| **Storage** | EBS volume types, Multi-Attach, filesystem formatting and mounting |
| **Networking** | VPC security groups, Application Load Balancer, target groups |
| **Security** | AWS WAF, Web ACLs, IP Sets, defense-in-depth architecture |
| **Linux** | Apache HTTPD, `lsblk`, `mkfs`, `mount`, bash scripting |
| **Architecture** | High availability patterns, layered security, shared storage design |

---

## About

Cloud engineer with hands-on experience designing and implementing AWS infrastructure solutions. These projects reflect real-world architecture patterns used in production environments — not toy examples.

- **AWS Services:** EC2, EBS, ALB, WAF, VPC, Security Groups
- **OS:** Amazon Linux 2023
- **Scripting:** Bash

---

*All projects are reproducible. Each README includes prerequisites and step-by-step instructions.*
