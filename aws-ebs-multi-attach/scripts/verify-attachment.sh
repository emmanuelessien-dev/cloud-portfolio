#!/bin/bash
# =============================================================================
# verify-attachment.sh
# Run on either EC2 instance to verify volume attachment and mount status
# =============================================================================

echo "================================================"
echo " EBS Multi-Attach — Attachment Verification"
echo "================================================"

echo ""
echo "[Block Devices]"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,RO

echo ""
echo "[Active Mounts on /mnt/shared]"
if mount | grep -q "/mnt/shared"; then
    mount | grep "/mnt/shared"
else
    echo "  /mnt/shared is not currently mounted on this instance."
fi

echo ""
echo "[Disk Usage on /mnt/shared]"
if mountpoint -q /mnt/shared; then
    df -h /mnt/shared
else
    echo "  /mnt/shared is not mounted — skipping disk usage."
fi

echo ""
echo "[Files on Shared Volume]"
if mountpoint -q /mnt/shared; then
    ls -lah /mnt/shared/
else
    echo "  Mount /mnt/shared first to list files."
fi

echo ""
echo "================================================"
echo " Verification complete."
echo "================================================"
