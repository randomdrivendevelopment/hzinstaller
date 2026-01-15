#!/bin/sh
#
# This is a simple wrapper to install encrypted LVM debian at Hetzner
# using their rescue shell and provided installimage scripts
#
# Usage:
# TARGET=root@yourhostname ./run.sh
#
# Environment variables:
# - TARGET          target user@host for ssh connection to rescue shell
# - INSTALL_CONFIG  installimage configuration file, default: installimage.conf
# - HOST            which hostname to set in new os, uses TARGET by default
# - KEY             encryption key, asks the user if not set
# - SSH_PUB_KEY     ssh public key to install to new os, 
#                   defualt: ~/.ssh/id_rsa.pub
# - REBOOT          set to 1 to automatically reboot into new system
# - INSTALL_PVE     set to 1 to install Proxmox VE

set -e

if [ -z "${TARGET}" ]; then
  echo Set TARGET env to ssh user/host
  exit 1
fi

if [ -z "${INSTALL_CONFIG}" ]; then
  INSTALL_CONFIG=installimage.conf
fi

if [ -z "${HOST}" ]; then
  HOST=`echo ${TARGET}|sed 's/^.*\@//'`
fi

if [ -z "${SSH_PUB_KEY}" ]; then
  SSH_PUB_KEY=~/.ssh/id_rsa.pub
fi

echo Host name to set: ${HOST}

scp ~/.ssh/id_rsa.pub       ${TARGET}:/tmp/authorized_keys
scp "${INSTALL_CONFIG}"     ${TARGET}:/tmp/installimage.conf
scp post-install.sh         ${TARGET}:/tmp/post-install.sh

if [ "$INSTALL_PVE" ]; then 
  cat install-pve.sh | ssh -T ${TARGET} 'cat >> /tmp/post-install.sh'
fi

if [ -z "$KEY" ]; then
  echo Enter disk encryption key:
  read -s KEY
fi

echo "CRYPTPASSWORD ${KEY}\nHOSTNAME ${HOST}" | ssh ${TARGET} -T 'cat >> /tmp/installimage.conf; chmod +x /tmp/post-install.sh; echo installimage -a -c /tmp/installimage.conf -x /tmp/post-install.sh \; rm -f /tmp/installimage.conf \; exit > /tmp/inst'
echo '. /tmp/inst' | ssh -tt ${TARGET} 
ssh ${TARGET} -T "rm -f /tmp/installimage.conf"

if [ "$REBOOT" ]; then 
  ssh -T ${TARGET} 'reboot'
fi

