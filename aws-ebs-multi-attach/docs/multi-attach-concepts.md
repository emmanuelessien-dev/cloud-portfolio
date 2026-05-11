# EBS Multi-Attach — Concepts & Filesystem Safety

## What Is Block Storage?

Block storage divides data into fixed-size chunks (blocks) and addresses them individually. Unlike object storage (S3) or file storage (EFS), block storage presents itself to the OS as a raw disk device — the OS or application is responsible for the filesystem layer.

Amazon EBS is AWS's block storage service. Each EBS volume is a virtual disk that EC2 instances can format and use like a physical hard drive.

---

## How EBS Multi-Attach Works

Normally, an EBS volume is exclusive to one EC2 instance. Multi-Attach removes this restriction for **io1 and io2 volumes**, allowing up to **16 EC2 instances** in the same Availability Zone to access the same volume simultaneously.

All attached instances share the same raw block device. There is no filesystem-level coordination built into EBS — that responsibility falls on the operating system or application.

---

## The Data Corruption Problem

Traditional single-host filesystems (ext4, XFS, NTFS) are designed with one assumption: **only one host accesses the filesystem at a time**. They use in-memory structures (the journal, inode tables, superblock) to track filesystem state.

When two hosts mount the same ext4 volume read-write simultaneously:
- Each host maintains its own in-memory view of the filesystem
- Writes from one host are not immediately visible to the other's in-memory state
- Both hosts may overwrite each other's metadata structures
- The result: filesystem corruption, data loss, or kernel panics

**This is not a limitation of Multi-Attach — it is a fundamental property of single-host filesystems.**

---

## The Safe Patterns

### Pattern 1: One Writer, Multiple Readers (this project)

Mount the volume read-write on exactly one instance. All other instances mount read-only.

```
EC2Server-1:  sudo mount /dev/nvme1n1 /mnt/shared           # read-write
EC2Server-2:  sudo mount -o ro /dev/nvme1n1 /mnt/shared     # read-only
```

**Trade-off:** Readers see data after it's been flushed from the writer's page cache to disk. There may be a small delay for very recent writes to become visible.

**Use cases:** Log aggregation readers, configuration distribution, read-heavy reporting workloads.

### Pattern 2: Cluster-Aware Filesystem

Use a filesystem explicitly designed for concurrent multi-host access, such as:

- **GFS2** (Red Hat Global Filesystem 2) — uses distributed locking via a Cluster Manager
- **OCFS2** (Oracle Cluster Filesystem 2) — uses a network-based locking protocol
- **Lustre** — high-performance parallel filesystem for HPC workloads

These filesystems coordinate writes across all hosts using a **distributed lock manager (DLM)**, preventing conflicting operations.

**Trade-off:** Significant additional configuration complexity. The DLM adds network round-trips for locking operations, which can impact write latency.

**Use cases:** Oracle RAC databases, clustered databases, HPC storage.

---

## AZ Constraint

EBS is an **Availability Zone-scoped service**. A volume in `us-east-1a` can only be attached to EC2 instances also in `us-east-1a`.

This is an important architectural constraint for Multi-Attach designs:
- All participating instances must be in the same AZ
- If an AZ fails, all instances AND the shared volume become unavailable simultaneously
- For cross-AZ resilience, consider Amazon EFS or replication strategies

---

## EBS Multi-Attach vs. EFS

| Feature | EBS Multi-Attach | Amazon EFS |
|---|---|---|
| Storage type | Block | File (NFS) |
| Concurrent writers | Only with cluster filesystem | Native (built-in) |
| AZ constraint | Same AZ only | Multi-AZ by default |
| Protocol | Block device | NFS v4 |
| OS support | Linux only (io1/io2) | Linux and some Windows |
| Performance | Very high IOPS (io2: up to 256K) | Scales automatically |
| Use case | Clustered DBs, high-IOPS shared storage | Shared application data, CMS |

---

## Production Considerations

1. **Monitoring:** Enable CloudWatch metrics for the EBS volume — track `VolumeReadOps`, `VolumeWriteOps`, and `VolumeQueueLength`
2. **Snapshots:** Take regular EBS snapshots for point-in-time backup, even with Multi-Attach enabled
3. **Persistent mounts:** Add the volume to `/etc/fstab` on both instances so it remounts automatically after a reboot (use `nofail` option to prevent boot failures if the volume is unavailable)
4. **IOPS sizing:** Provision IOPS based on your actual workload. Under-provisioned IOPS causes queue buildup and latency
5. **Cost:** io1/io2 volumes are significantly more expensive than gp3. Use Multi-Attach only when the use case genuinely requires it

### /etc/fstab entry (persistent mount — writer instance)
```
/dev/nvme1n1    /mnt/shared    ext4    defaults,nofail    0    2
```

### /etc/fstab entry (persistent mount — reader instance)
```
/dev/nvme1n1    /mnt/shared    ext4    ro,nofail    0    2
```
