#!/bin/sh

# This script enables dropbear for unlocks

set -e

# Update system
apt-get update >/dev/null
apt-get -y install cryptsetup-initramfs dropbear-initramfs

if [ "${IPV6_INITRD}" = "static" ]; then
  if [ -z "${IPV6_GW}" ]; then
    IPV6_GW="fe80::1"
  fi
  if [ -z "${IPV6_IF}" ]; then
    IPV6_IF=`cat /proc/net/if_inet6 | grep -v -E "^(fe80|00|fc|fd)" | grep -o -E "\w+$"|head -1`
    if [ `echo $IPV6_IF | grep ^eth` ]; then
      IPV6_IF=`ip link show dev $IPV6_IF | grep altname | grep -o -E '\w+$'`
    fi
  fi
  if [ -z "${IPV6_ADDR}" ]; then
    IPV6_ADDR=`ip -6 addr show dev ${IPV6_IF} scope global|grep inet6|sed -E 's/^\s+//'|cut -d ' ' -f 2|grep -v -E '^(fc\w\w:|fd\w\w:)'|head -1`
  fi
  INITRD_SH=/etc/initramfs-tools/scripts/init-premount/ipv6
  echo 'if [ "$1" = "prereqs" ]; then exit 0; fi' >> ${INITRD_SH}
  echo /sbin/ip link set ${IPV6_IF} up >> ${INITRD_SH}
  echo /sbin/ip -6 addr add ${IPV6_ADDR} dev ${IPV6_IF} >> ${INITRD_SH}
  echo /sbin/ip -6 route add default via ${IPV6_GW} dev ${IPV6_IF} >> ${INITRD_SH}
  chmod +x ${INITRD_SH}
fi

# Copy SSH keys for dropbear and change the port
cp /root/.ssh/authorized_keys /etc/dropbear/initramfs/
sed -ie 's/#DROPBEAR_OPTIONS=/DROPBEAR_OPTIONS="-I 600 -j -k -p 2222 -s"/' /etc/dropbear/initramfs/dropbear.conf
dpkg-reconfigure dropbear-initramfs
update-initramfs -u

