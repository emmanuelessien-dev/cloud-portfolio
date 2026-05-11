# WAF Rule & Web ACL Configuration Reference

## Web ACL: MywebACL

| Setting | Value |
|---|---|
| Name | MywebACL |
| Scope | Regional |
| Region | US East (N. Virginia) |
| Associated resource | `Web-server-LB` (Application Load Balancer) |
| Default action | Allow (deny-list model) |

---

## Rule: MywebACL-rule

| Setting | Value |
|---|---|
| Rule type | IP Set |
| IP Set | MyIPset |
| IP address field | Source IP address |
| Action | Block |
| Priority | 1 (only rule) |

---

## IP Set: MyIPset

| Setting | Value |
|---|---|
| Name | MyIPset |
| Region | US East (N. Virginia) |
| IP version | IPv4 |
| Format | CIDR notation (e.g., `203.0.113.0/32` for a single host) |

> **Important:** The `/32` suffix is required for single-host IPs. Without it, WAF will reject the entry.

---

## WAF Action Reference

| Action | Behavior | Use case |
|---|---|---|
| **Allow** | Passes the request through to the ALB | Explicit allow-list entries |
| **Block** | Returns `403 Forbidden` to the client; request never reaches the ALB | Blocking known bad actors |
| **Count** | Logs the request but does not block it | Testing rules before enforcing them |
| **CAPTCHA** | Returns a CAPTCHA challenge | Differentiating humans from bots |

---

## Deny-List vs. Allow-List Models

This project uses a **deny-list** (block-list) model:
- Default action: **Allow**
- Explicit rules: **Block** specific IPs

**When to use deny-list:** You want to allow all traffic by default and only block known threats. Good for general-purpose web applications.

**When to use allow-list:**
- Default action: **Block**
- Explicit rules: **Allow** known IPs only

Good for internal applications, admin panels, or APIs only accessed from known networks.

---

## Extending This Solution

This WAF configuration can be extended with additional rule types:

- **Rate-based rules** — Block IPs that exceed a request threshold (e.g., 2000 requests per 5 minutes) to prevent DDoS and brute force
- **Managed rule groups** — AWS-maintained rule sets covering OWASP Top 10, SQL injection, XSS, and known bad inputs — no manual rule authoring required
- **Geographic match rules** — Block or allow traffic based on country of origin
- **String/regex match rules** — Inspect query strings, headers, URI paths, or request bodies for malicious patterns
