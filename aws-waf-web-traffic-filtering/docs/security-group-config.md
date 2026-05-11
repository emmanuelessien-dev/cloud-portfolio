# Security Group Configuration Reference

This document details the security group design used in this project, explaining the rationale behind each rule.

---

## Design Philosophy

Web servers should **never be directly accessible from the internet**. All public traffic must pass through the load balancer, which acts as a controlled entry point. This is enforced by making the web server security group accept HTTP traffic *only from the load balancer's security group*, not from `0.0.0.0/0`.

This is a standard **layered security** pattern in AWS architectures.

---

## LoadBalancer-SG

**Purpose:** Applied to the Application Load Balancer. Accepts public internet traffic on port 80.

| Direction | Type | Protocol | Port | Source | Reason |
|---|---|---|---|---|---|
| Inbound | HTTP | TCP | 80 | `0.0.0.0/0` | Accept traffic from all internet users |
| Outbound | All traffic | All | All | `0.0.0.0/0` | Allow ALB to forward responses |

---

## webserver-SG

**Purpose:** Applied to both EC2 web server instances. Restricts HTTP access to traffic originating from the ALB only.

| Direction | Type | Protocol | Port | Source | Reason |
|---|---|---|---|---|---|
| Inbound | HTTP | TCP | 80 | `LoadBalancer-SG` | Only the ALB can send HTTP traffic to the servers |
| Inbound | SSH | TCP | 22 | `0.0.0.0/0` | Administrative access (tighten to known IPs in production) |
| Outbound | All traffic | All | All | `0.0.0.0/0` | Allow servers to respond and reach internet (for updates) |

---

## Security Notes

- In production, SSH access should be restricted to a known IP or bastion host CIDR, not `0.0.0.0/0`
- Consider enabling **VPC Flow Logs** to monitor traffic patterns for both security groups
- The ALB itself can be further protected by enabling **AWS Shield Standard** (included at no extra cost) for DDoS protection at the network layer
