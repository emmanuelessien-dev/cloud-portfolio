# AWS EBS Multi-Attach — Shared Block Storage for High-Availability Workloads

![AWS](https://img.shields.io/badge/AWS-EBS%20%7C%20EC2-orange?logo=amazon-aws)
![Domain](https://img.shields.io/badge/Domain-Storage%20%7C%20High%20Availability-blue)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

## Overview

This project demonstrates how to configure **Amazon EBS Multi-Attach** to share a single provisioned IOPS SSD (io1) volume across multiple EC2 instances within the same Availability Zone. The implementation follows safe access patterns — one instance mounts the volume as **read-write** (writer), and the second mounts it as **read-only** (reader) — to simulate a real-world shared storage scenario without risking data corruption from concurrent writes.

This architecture pattern is foundational for clustered applications, distributed databases, and scenarios requiring shared persistent storage across compute nodes.

---

## Problem Statement

Many cloud workloads — clustered databases, distributed file processing systems, and high-availability applications — require multiple compute instances to access the **same underlying block storage** simultaneously. The default EBS behavior restricts a volume to a single EC2 instance at a time, creating a bottleneck for such architectures.

**The goal:** Configure shared block storage across two EC2 instances using EBS Multi-Attach, demonstrate controlled read-write access patterns to prevent data corruption, and validate that data written by one instance is immediately readable by another.

---

## Architecture

```
                    ┌────────────────────────────────────────────────┐
                    │                  AWS Cloud                      │
                    │              (us-east-1a)                       │
                    │                                                  │
  ┌──────────┐      │   ┌─────────────────┐      ┌─────────────────┐ │
  │ External │      │   │  EC2Server-1    │      │  EC2Server-2    │ │
  │ Client   │─────►│   │  (Writer)       │      │  (Reader)       │ │
  └──────────┘      │   │                 │      │                 │ │
                    │   │  Mount: rw      │      │  Mount: ro      │ │
                    │   │  /mnt/shared    │      │  /mnt/shared    │ │
                    │   └────────┬────────┘      └────────┬────────┘ │
                    │            │  multi-attach           │          │
                    │            └──────────┬──────────────┘          │
                    │                       │                          │
                    │            ┌──────────▼──────────┐              │
                    │            │   EBS io1 Volume     │              │
                    │            │   10 GiB | 500 IOPS  │              │
                    │            │   Multi-Attach ON    │              │
                    │            └─────────────────────┘              │
                    │                                                  │
                    └────────────────────────────────────────────────┘
```

**Data flow:**
1. EC2Server-1 (Writer) mounts the EBS volume read-write, formats it, and writes data
2. EC2Server-2 (Reader) mounts the same volume read-only
3. Data written by Server-1 is immediately accessible on Server-2 via the shared block device
4. Read-only mount on Server-2 prevents accidental writes that could corrupt the ext4 filesystem

---

## AWS Services Used

| Service | Role |
|---|---|
| **Amazon EBS (io1)** | Provisioned IOPS SSD volume with Multi-Attach enabled |
| **Amazon EC2** | Compute instances (writer and reader nodes) |
| **EC2 Instance Connect** | Browser-based SSH for instance management |
| **Security Groups** | SSH access control for EC2 instances |

---

## Why io1 / io2 for Multi-Attach?

EBS Multi-Attach is **only supported on Provisioned IOPS SSD volumes (io1 or io2)**. Standard `gp2`/`gp3` volumes do not support this feature.

| Volume Type | Multi-Attach | IOPS | Use Case |
|---|---|---|---|
| gp3 | ❌ No | Up to 16,000 | General purpose |
| io1 | ✅ Yes | Up to 64,000 | High-performance, shared storage |
| io2 | ✅ Yes | Up to 256,000 | Mission-critical, shared storage |

The io1 volume in this project was configured with **500 IOPS** — the minimum for a 10 GiB volume — which is appropriate for a demonstration workload.

---

## Why Read-Only on the Second Instance?

EBS Multi-Attach provides shared **block-level** access, not a distributed filesystem. Unlike Amazon EFS (which handles concurrent access natively), a block volume with a traditional filesystem like **ext4 does not coordinate writes between multiple hosts**.

If both instances mounted the volume read-write simultaneously, concurrent filesystem operations could cause **metadata corruption**, **data loss**, or **filesystem errors**.

**The safe pattern** for ext4 + Multi-Attach:
- **One writer** mounts read-write (`rw`)
- **All other consumers** mount read-only (`ro`)

For true concurrent multi-writer access on shared block storage, a **cluster-aware filesystem** (e.g., GFS2, OCFS2) is required at the OS level.

---

## Implementation

### Phase 1 — EC2 Instance Provisioning

Launched **two EC2 instances** in the same Availability Zone (`us-east-1a`):

| Instance | Name | Type | AZ | Role |
|---|---|---|---|---|
| i-xxxx | EC2Server-1 | t3.micro | us-east-1a | Writer (read-write mount) |
| i-yyyy | EC2Server-2 | t3.micro | us-east-1a | Reader (read-only mount) |

Both instances use **Amazon Linux 2023** and share a single security group (`SSH_SG`) that allows SSH access for administration.

> **Critical:** Both instances must be in the same AZ as the EBS volume. EBS is an AZ-scoped resource — it cannot be attached to instances in a different AZ.

### Phase 2 — EBS Volume Creation

Created an **io1 volume** with Multi-Attach explicitly enabled:

| Parameter | Value | Notes |
|---|---|---|
| Volume type | io1 (Provisioned IOPS SSD) | Required for Multi-Attach |
| Size | 10 GiB | Minimum supported by io1 |
| IOPS | 500 | Minimum provisioned IOPS for io1 |
| Availability Zone | us-east-1a | Must match EC2 instances |
| Multi-Attach | Enabled ✅ | Must be checked at creation time |

> **Important:** Multi-Attach cannot be enabled after volume creation. It must be set during the initial `Create Volume` step.

### Phase 3 — Volume Attachment

Attached the same volume to both instances via `Actions > Attach Volume`:

- **EC2Server-1:** Device name `/dev/sdf` → visible inside OS as `/dev/nvme1n1`
- **EC2Server-2:** Device name `/dev/sdf` → visible inside OS as `/dev/nvme1n1`

> AWS Linux kernels rename block devices. `/dev/sdf` in the console appears as `/dev/nvme1n1` inside the instance. Always use `lsblk` to identify the actual device name.

### Phase 4 — Filesystem Formatting and Mounting

See [`scripts/mount-writer.sh`](./scripts/mount-writer.sh) and [`scripts/mount-reader.sh`](./scripts/mount-reader.sh) for the exact commands.

**On EC2Server-1 (Writer):**

```bash
# Format the volume — ONLY run this once, on one instance
sudo mkfs.ext4 /dev/nvme1n1

# Create mount directory and mount read-write
sudo mkdir -p /mnt/shared
sudo mount /dev/nvme1n1 /mnt/shared

# Write a test file
echo "Hello from Instance A" | sudo tee /mnt/shared/test.txt
cat /mnt/shared/test.txt
# Output: Hello from Instance A
```

**On EC2Server-2 (Reader):**

```bash
# Create mount directory and mount read-only
sudo mkdir -p /mnt/shared
sudo mount -o ro /dev/nvme1n1 /mnt/shared

# Read the file written by Instance A
cat /mnt/shared/test.txt
# Output: Hello from Instance A ✅
```

### Phase 5 — Validation

EC2Server-2 successfully read the file written by EC2Server-1 from the shared volume, confirming:
- The Multi-Attach configuration is working correctly
- The ext4 filesystem is intact and consistent
- The read-only mount prevents accidental writes from the reader instance

---

## Project Structure

```
aws-ebs-multi-attach/
├── README.md
├── scripts/
│   ├── mount-writer.sh          # Commands for the writer instance (EC2Server-1)
│   ├── mount-reader.sh          # Commands for the reader instance (EC2Server-2)
│   └── verify-attachment.sh     # Verify volume attachment and mount status
└── docs/
    ├── multi-attach-concepts.md  # Deep dive into EBS Multi-Attach and filesystem safety
    └── troubleshooting.md        # Common issues and fixes
```

---

## How to Reproduce

### Prerequisites
- AWS account with EC2 and EBS permissions
- Two EC2 instances in the **same Availability Zone**
- An io1 or io2 EBS volume with Multi-Attach enabled

### Steps

1. **Launch two EC2 instances** in the same AZ (e.g., `us-east-1a`) — both on Amazon Linux 2023
2. **Create an io1 EBS volume** — set AZ to match instances, check **Enable Multi-Attach**
3. **Attach the volume** to both instances via `Actions > Attach Volume`
4. **SSH into EC2Server-1** and run [`scripts/mount-writer.sh`](./scripts/mount-writer.sh)
5. **SSH into EC2Server-2** and run [`scripts/mount-reader.sh`](./scripts/mount-reader.sh)
6. **Verify** that EC2Server-2 can read the file written by EC2Server-1

---

## Outcomes & Learnings

- Gained practical experience configuring **EBS Multi-Attach** on io1 volumes
- Understood **why Multi-Attach requires io1/io2** and is not available on gp2/gp3
- Learned about the **data corruption risks** of concurrent read-write mounts with non-cluster-aware filesystems
- Practiced safe mount patterns: **one writer, multiple readers** for ext4 volumes
- Understood the **AZ-scoped nature** of EBS and the architectural constraints this creates
- Verified real-time shared data access between EC2 instances using a shared block device
- Compared EBS Multi-Attach with **Amazon EFS** as an alternative for workloads needing true concurrent write access

---

## When to Use EBS Multi-Attach vs. Alternatives

| Requirement | Recommended Solution |
|---|---|
| Shared block storage, one writer | EBS Multi-Attach (io1/io2) with ro mounts for readers |
| Concurrent multi-writer block storage | EBS Multi-Attach + cluster filesystem (GFS2, OCFS2) |
| Shared file storage, multiple writers | Amazon EFS (fully managed NFS) |
| Object storage, multiple writers | Amazon S3 |
| High-performance shared NFS | Amazon FSx for NetApp ONTAP |

---

## References

- [EBS Multi-Attach Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes-multi.html)
- [EBS Volume Types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)
- [Amazon EFS vs EBS Comparison](https://docs.aws.amazon.com/efs/latest/ug/efs-vs-ebs.html)

---

*Part of my AWS Cloud Engineering Portfolio — see other projects [here](../)*
