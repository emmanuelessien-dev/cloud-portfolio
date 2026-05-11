#!/bin/bash
# =============================================================================
# mount-reader.sh
# Run this on EC2Server-2 (the reader instance)
#
# This script:
#   1. Creates a mount point at /mnt/shared
#   2. Mounts the shared EBS volume as READ-ONLY to prevent data corruption
#   3. Reads the test file written by EC2Server-1 to validate shared access
#
# IMPORTANT: The volume must already be formatted and have data written
#            by EC2Server-1 (mount-writer.sh) before running this script.
#
# The read-only (-o ro) flag is critical with ext4 + Multi-Attach.
# Concurrent rw mounts from multiple hosts WILL corrupt the filesystem.
# =============================================================================

set -e  # Exit immediately if any command fails

echo "========================================"
echo " EBS Multi-Attach — Reader Instance Setup"
echo "========================================"

# -----------------------------------------------------------------------
# Step 1: Identify the EBS volume
# -----------------------------------------------------------------------
echo ""
echo "[1/3] Listing block devices..."
lsblk

echo ""
echo "The Multi-Attach EBS volume should appear as 'nvme1n1' (10G, type: disk)."
echo "Proceeding with /dev/nvme1n1 ..."

# -----------------------------------------------------------------------
# Step 2: Mount the volume READ-ONLY
# -----------------------------------------------------------------------
echo ""
echo "[2/3] Creating mount point and mounting read-only..."
sudo mkdir -p /mnt/shared

# The -o ro flag is essential — mounts as read-only
sudo mount -o ro /dev/nvme1n1 /mnt/shared
echo "      Mounted /dev/nvme1n1 at /mnt/shared (READ-ONLY)"

# Verify the mount and confirm it's read-only
echo ""
echo "      Mount verification (confirm 'ro' flag is present):"
mount | grep /mnt/shared

# -----------------------------------------------------------------------
# Step 3: Read the test file written by EC2Server-1
# -----------------------------------------------------------------------
echo ""
echo "[3/3] Reading test file from shared volume..."
echo ""

if [ -f /mnt/shared/test.txt ]; then
    echo "      Contents of /mnt/shared/test.txt:"
    cat /mnt/shared/test.txt
    echo ""
    echo "========================================"
    echo " SUCCESS: Shared volume access confirmed."
    echo " Data written by EC2Server-1 is visible"
    echo " on EC2Server-2 via EBS Multi-Attach."
    echo "========================================"
else
    echo "      ERROR: test.txt not found on the shared volume."
    echo "      Ensure mount-writer.sh was run on EC2Server-1 first."
    exit 1
fi
