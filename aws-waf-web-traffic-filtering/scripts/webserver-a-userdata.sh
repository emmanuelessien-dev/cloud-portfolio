#!/bin/bash
# =============================================================================
# webserver-a-userdata.sh
# EC2 User Data bootstrap script — Web Server A
#
# Purpose: Installs and configures Apache HTTPD on Amazon Linux 2023.
#          Serves a unique response page to verify ALB load distribution.
#
# Usage: Paste into EC2 > Launch Instance > Advanced Details > User Data
# =============================================================================

sudo su

# Update all system packages
dnf update -y

# Install Apache HTTP Server
dnf install -y httpd

# Start the HTTPD service immediately
systemctl start httpd

# Enable HTTPD to start automatically on reboot
systemctl enable httpd

# Write the index page — unique identifier for this server
echo "Response coming from server A" > /var/www/html/index.html
