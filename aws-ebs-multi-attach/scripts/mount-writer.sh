#!/bin/bash
# =============================================================================
# mount-writer.sh
# Run this on EC2Server-1 (the writer instance)
#
# This script:
#   1. Identifies the attached EBS volume
#   2. Formats it with ext4 (ONE TIME ONLY — do not re-run after first use)
#   3. Mounts it read-write at /mnt/shared
#   4. Writes a test file to verify the setup
#
# WARNING: mkfs.ext4 destroys all existing data on the device.
#          Only run the format step once, on the first setup.
# =============================================================================

set -e  # Exit immediately if any command fails

echo "========================================"
echo " EBS Multi-Attach — Writer Instance Setup"
echo "========================================"

# -----------------------------------------------------------------------
# Step 1: Identify the EBS volume
# -----------------------------------------------------------------------
echo ""
echo "[1/4] Listing block devices..."
lsblk

echo ""
echo "The Multi-Attach EBS volume should appear as 'nvme1n1' (10G, type: disk)."
echo "Proceeding with /dev/nvme1n1 ..."
echo ""

# -----------------------------------------------------------------------
# Step 2: Format the volume
# Run ONLY ONCE on first setup. Comment this out on subsequent runs.
# -----------------------------------------------------------------------
echo "[2/4] Formatting /dev/nvme1n1 with ext4..."
echo "      (Skip this step if the volume was already formatted)"
sudo mkfs.ext4 /dev/nvme1n1
echo "      Format complete."

# -----------------------------------------------------------------------
# Step 3: Mount the volume read-write
# -----------------------------------------------------------------------
echo ""
echo "[3/4] Creating mount point and mounting read-write..."
sudo mkdir -p /mnt/shared
sudo mount /dev/nvme1n1 /mnt/shared
echo "      Mounted /dev/nvme1n1 at /mnt/shared (read-write)"

# Verify the mount
echo ""
echo "      Mount verification:"
mount | grep /mnt/shared

# -----------------------------------------------------------------------
# Step 4: Write a test file
# -----------------------------------------------------------------------
echo ""
echo "[4/4] Writing test file to shared volume..."
echo "Hello from Instance A" | sudo tee /mnt/shared/test.txt

echo ""
echo "      Confirming file contents:"
cat /mnt/shared/test.txt

echo ""
echo "========================================"
echo " Setup complete on writer instance."
echo " EC2Server-2 (reader) can now mount the"
echo " same volume read-only and read test.txt"
echo "========================================"
