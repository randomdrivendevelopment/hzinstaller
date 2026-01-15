#!/bin/sh

# This script enables dropbear for unlocks

set -e

# Update system
apt-get update >/dev/null
apt-get -y install cryptsetup-initramfs dropbear-initramfs

# Copy SSH keys for dropbear and change the port
cp /root/.ssh/authorized_keys /etc/dropbear/initramfs/
sed -ie 's/#DROPBEAR_OPTIONS=/DROPBEAR_OPTIONS="-I 600 -j -k -p 2222 -s"/' /etc/dropbear/initramfs/dropbear.conf
dpkg-reconfigure dropbear-initramfs
update-initramfs -u

