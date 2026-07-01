#!/bin/sh
set -e
# Packages and repos are handled by alpine-make-vm-image (packages.txt + repositories).
# This script runs chrooted into the image for everything that needs service setup.

# ---------------------------------------------------------------------------
# Cgroups
# ---------------------------------------------------------------------------
rc-update add cgroups boot
rc-service cgroups start 2>/dev/null || true

# ---------------------------------------------------------------------------
# KVM modules — load both at boot; only the matching one will actually load.
# ---------------------------------------------------------------------------
echo "kvm"       >> /etc/modules
echo "kvm_intel" >> /etc/modules
echo "kvm_amd"   >> /etc/modules

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------
rc-update add libvirtd boot
rc-update add docker boot

# ---------------------------------------------------------------------------
# Convenience aliases
# ---------------------------------------------------------------------------
echo "alias k='kubectl'" > /etc/profile.d/00-aliases.sh
