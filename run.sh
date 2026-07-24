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
# - IFACE_FILE      network interface file, default: ${HOST}.iface
#                   if exists - gets placed to /etc/network/interfaces
# - IPV6_INITRD     set to 'static' to configure static IPv6 in initrd.
#                   if no other IPV6_* variables set - it will try autodetect
# - IPV6_ADDR       IPv6 address/prefix - example: abcd:abcd:abcd:abcd/64
# - IPV6_GW         IPv6 default gw, default: fe80::1
# - IPV6_IF         IPv6 interface name, default: autodetect
#

set -e

cd $(dirname $(readlink -f $0))

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

if [ -z "${IFACE_FILE}" ] && [ -f "./${HOST}.iface" ]; then
  IFACE_FILE="./${HOST}.iface"
fi

echo Host name to set: ${HOST}

POSTINSTALL=`mktemp`

echo '#!/bin/bash' >> ${POSTINSTALL}
echo 'set -e' >> ${POSTINSTALL}

if [ "${IPV6_INITRD}" ]; then
  echo "IPV6_INITRD='${IPV6_INITRD}'" >> ${POSTINSTALL}
  echo "IPV6_IF='${IPV6_IF}'" >> ${POSTINSTALL}
  echo "IPV6_ADDR='${IPV6_ADDR}'" >> ${POSTINSTALL}
  echo "IPV6_GW='${IPV6_GW}'" >> ${POSTINSTALL}
fi

cat post-install.sh >> ${POSTINSTALL}

scp "${SSH_PUB_KEY}"    ${TARGET}:/tmp/authorized_keys
scp "${INSTALL_CONFIG}" ${TARGET}:/tmp/installimage.conf
scp "${POSTINSTALL}"    ${TARGET}:/tmp/post-install.sh

rm -f "${POSTINSTALL}"

TARGET=`echo $TARGET|tr -d '[]'`

if [ "$INSTALL_PVE" ]; then 
  cat install-pve.sh | ssh -T ${TARGET} 'cat >> /tmp/post-install.sh'
fi

if [ "$IFACE_FILE" ]; then 
  echo 'cat > /etc/network/interfaces <<EOF' | ssh -T ${TARGET} 'cat >> /tmp/post-install.sh'
  cat ${IFACE_FILE} | ssh -T ${TARGET} 'cat >> /tmp/post-install.sh'
  echo 'EOF' | ssh -T ${TARGET} 'cat >> /tmp/post-install.sh'
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

