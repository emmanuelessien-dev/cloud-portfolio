# Removing an IP from a WAF IP Set (Unblocking)

This document covers how to remove an IP address from a WAF IP Set using both the AWS Console and AWS CLI.

---

## Option 1 — AWS Console

1. Navigate to **AWS WAF & Shield** under Security, Identity, & Compliance
2. In the left panel, click **IP sets**
3. Click on **MyIPset**
4. Select the checkbox next to the IP address you want to remove
5. Click **Delete**
6. Type `delete` in the confirmation box and click **Delete**
7. Wait 1–2 minutes for WAF to propagate the change

---

## Option 2 — AWS CLI

### Step 1: Get the IP Set ID and lock token

```bash
aws wafv2 list-ip-sets \
  --scope REGIONAL \
  --region us-east-1
```

Note the `Id` and `LockToken` from the output for `MyIPset`.

### Step 2: Update the IP Set to remove the IP

Replace `YOUR_IP_SET_ID` and `YOUR_LOCK_TOKEN` with the values from Step 1.

```bash
aws wafv2 update-ip-set \
  --name MyIPset \
  --scope REGIONAL \
  --region us-east-1 \
  --id YOUR_IP_SET_ID \
  --addresses [] \
  --lock-token YOUR_LOCK_TOKEN
```

> **Note:** Setting `--addresses []` clears all IPs from the set.  
> To remove only a specific IP while keeping others, list only the IPs you want to *keep* in `--addresses`.

### Step 3: Verify

```bash
aws wafv2 get-ip-set \
  --name MyIPset \
  --scope REGIONAL \
  --region us-east-1 \
  --id YOUR_IP_SET_ID
```

The `Addresses` field should now be empty (or contain only the IPs you kept).

---

## Verification

After the WAF update propagates (~1–2 minutes), access the ALB DNS endpoint from the previously blocked IP. You should receive a valid HTTP response from one of the web servers instead of `403 Forbidden`.
