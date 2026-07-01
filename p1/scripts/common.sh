#!/bin/sh
set -e

# Common setup run on every node (server and worker).
apk add --no-cache curl bash iptables ip6tables

rc-update add cgroups boot
rc-service cgroups start 2>/dev/null || true

# Handy 'k' alias for kubectl in login shells (Alpine sources /etc/profile.d/*.sh).
echo "alias k='kubectl'" > /etc/profile.d/00-aliases.sh
