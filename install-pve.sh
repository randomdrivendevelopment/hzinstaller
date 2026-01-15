#!/bin/sh
#
# This script intended to be concatinated with post-install.sh or used
# stand-alone for installing minimal Proxmox PVE
#

set -e

cat > /etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

cat > /etc/apt/sources.list.d/ceph.sources << EOF
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

wget https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg -O /usr/share/keyrings/proxmox-archive-keyring.gpg
sha256sum /usr/share/keyrings/proxmox-archive-keyring.gpg | grep 136673be77aba35dcce385b28737689ad64fd785a797e57897589aed08db6e45

apt-get update
echo Installing Postfix...
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
echo Installing PVE package...
apt-get install -y proxmox-ve

