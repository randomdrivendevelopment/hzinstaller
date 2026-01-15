# Hetzner installimage automation wrapper

This is a simple wrapper to install encrypted LVM debian at Hetzner
using their rescue shell and provided installimage scripts

## Quickstart

- Set your server to Rescue mode
- Clear your old server key from `~/.ssh/known_hosts`
- Run the command: `REBOOT=1 TARGET=root@yourhostname ./run.sh`
- Accept rescue system key, provide your desired disk encryption key
- Installation is unattended and will ignore any other input
- Clear your `~/.ssh/known_hosts` again
- Wait for a while, ssh to port 2222: `ssh root@yourhostname -p2222`
- Run the command `cryptroot-unlock` and enter your disk encryption key
- Use your server as usual, run the previous step on any reboot

## Sctipt parameters

Environment variables:
- `TARGET`          target user@host for ssh connection to rescue shell
- `INSTALL_CONFIG`  installimage configuration file, default: installimage.conf
- `HOST`            which hostname to set in new os, uses TARGET by default
- `KEY`             encryption key, asks the user if not set
- `SSH_PUB_KEY`     ssh public key to install to new os, 
                    defualt: `~/.ssh/id_rsa.pub`
- `REBOOT`          set to 1 to automatically reboot into new system
- `INSTALL_PVE`     set to 1 to automatically install Proxmox VE
- `IFACE_FILE`      network interface configuration file, 
                    default: `./${HOST}.iface`.
                    If file exists - it gets placed to /etc/network/interfaces

## Troubleshooting

In case something went wrong, remove REBOOT=1 parameter, re-run installation
and ssh into rescue shell. Check log files inside home directory.

## Notes

This script is pretty dumb and error handling is very limited.
If you want to use it for any serious automation you will have to add your own
system tests around it.

