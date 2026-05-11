# Troubleshooting Guide — EBS Multi-Attach

## Issue: Volume does not appear in `lsblk`

**Symptom:** After attaching the volume in the AWS console, running `lsblk` on the EC2 instance does not show the new device.

**Causes & Fixes:**

1. **AZ mismatch** — The volume is in a different AZ than the instance. Verify both are in `us-east-1a` (or the same AZ). EBS cannot attach across AZs.

2. **Volume not in `available` state** — The volume may still be in a `creating` or `in-use` state from a previous attachment. Check the Volumes list in the EC2 console.

3. **Attachment still propagating** — Wait 30–60 seconds after attaching and run `lsblk` again.

---

## Issue: `mkfs.ext4` fails with "device is busy"

**Symptom:** The format command returns `Device or resource busy`.

**Cause:** The volume is already mounted somewhere.

**Fix:**
```bash
# Check if the device is mounted
mount | grep nvme1n1

# Unmount if necessary
sudo umount /dev/nvme1n1

# Then retry formatting
sudo mkfs.ext4 /dev/nvme1n1
```

---

## Issue: `mount` fails with "wrong fs type" or "bad superblock"

**Symptom:** Mounting the volume on the reader instance fails with a superblock error.

**Cause:** The volume was never formatted, or it was formatted with a different filesystem.

**Fix:** Return to the writer instance and confirm formatting was completed successfully:
```bash
# Check filesystem type on the device
sudo file -s /dev/nvme1n1
```
Expected output: `Linux rev 1.0 ext4 filesystem data ...`

If the output is `data` (no filesystem detected), run `sudo mkfs.ext4 /dev/nvme1n1` on the writer.

---

## Issue: Reader instance can see the mount point but the file is empty or missing

**Symptom:** `/mnt/shared/test.txt` exists on the reader but is empty, or `cat` returns nothing.

**Cause:** The writer instance wrote the file but it has not been flushed from the page cache to the physical disk yet.

**Fix:** On the writer instance, flush pending writes to disk:
```bash
sync
sudo blockdev --flushbufs /dev/nvme1n1
```
Then re-read the file on the reader instance.

---

## Issue: Attempting to write on the reader instance returns "Read-only file system"

**Symptom:**
```
bash: /mnt/shared/newfile.txt: Read-only file system
```

**This is expected behaviour** — the read-only mount is working correctly. This error confirms the reader cannot write to the shared volume, which prevents data corruption.

If you need the reader to also write, you must implement a cluster-aware filesystem (GFS2, OCFS2). See [`docs/multi-attach-concepts.md`](./multi-attach-concepts.md) for details.

---

## Issue: Cannot enable Multi-Attach on an existing volume

**Symptom:** The Multi-Attach checkbox is greyed out or the option to enable it is missing.

**Cause:** Multi-Attach can only be enabled at volume creation time. It cannot be retrofitted onto an existing volume.

**Fix:** Create a new io1 or io2 volume with Multi-Attach enabled from the start. If you need to migrate data from an existing volume, take a snapshot and create a new volume from it with Multi-Attach enabled.

---

## Issue: Both instances are in the same region but Multi-Attach still fails

**Symptom:** Attaching the volume to the second instance fails with an error about incompatible AZs.

**Cause:** The instances are in the same **region** but different **Availability Zones** (e.g., one in `us-east-1a`, one in `us-east-1b`).

**Fix:** Confirm both instances are in the exact same AZ. Check under EC2 > Instances > Availability Zone column. If they are in different AZs, you will need to stop one instance and migrate it (e.g., by creating an AMI and re-launching in the correct AZ).
