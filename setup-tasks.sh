#!/usr/bin/env bash
# setup tasks
set -ex

# AS ROOT:

# Update apt
apt update
apt dist-upgrade

# Set timezone
timedatectl set-timezone Etc/UTC

# Create new user:
useradd -mU -s /bin/bash -G sudo alexw
passwd alexw
# interactive input for password

# Allow SSH access:
mkdir -p /home/alexw/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHUvHyAEWS7YXWrsB96v0tY+he2a6lCaz+C00upGluLT Alex Laptop - Linux - 2017-01
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItYOq4o5XYmB3K8D6N12jNtH785vLCvDfoP1L7kdOT/ Alex Laptop - Windows - 2018-07-12
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBqN+0jjjUHptHf0QfLxWPdaGMECEljXwe2Z8ANOlNxB Alex Desktop - 10 Pro WSFL - 2018-12-31
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWRg5sK3tL0pAgZRjabec/wQaSLlNXu57RxssFGheDg Alex MacBook 2020-04-26
" > /home/alexw/.ssh/authorized_keys
chmod 0644 /home/alexw/.ssh/authorized_keys
chown alexw:alexw /home/alexw/.ssh/authorized_keys

# Remove cloud-provider provisioned keys and secure ssh
rm -f ~/.ssh/authorized_keys

echo "
Port 8443
LoginGraceTime 60s
StrictModes yes

MaxAuthTries 2
PermitRootLogin no
AllowUsers alexw

PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
HostbasedAuthentication no
PasswordAuthentication no
ChallengeResponseAuthentication yes
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM yes
AuthenticationMethods publickey,keyboard-interactive

AllowAgentForwarding no
AllowTcpForwarding yes
X11Forwarding no
PrintMotd no
UseDNS no

AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
" > /etc/ssh/sshd_config
rm -rf /etc/ssh/sshd_config.d

sshd -t
systemctl restart sshd


# Install fail2ban
apt install fail2ban
systemctl enable fail2ban

echo "
[INCLUDES]
before = paths-debian.conf

[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5
maxmatches = %(maxretry)s
backend = auto
usedns = raw

# Jails
mode = normal
filter = %(__name__)s[mode=%(mode)s]

# Actions
port = 0:65535
banaction = iptables-multiport
banaction_allports = iptables-allports

action_ = %(banaction)s[name=%(__name__)s, port=\"%(port)s\", protocol=\"%(protocol)s\", chain=\"%(chain)s\"]
action = %(action_)s

[sshd]
enabled = true
port = 8443
mode = aggressive
logpath = %(sshd_log)s
backend = %(sshd_backend)s
" > /etc/fail2ban/jail.local
systemctl restart fail2ban


# Set up google authenticator
apt install libpam-google-authenticator
su - alexw -c google-authenticator
# interactive input required

echo "
4c4
< @include common-auth
---
> # @include common-auth
55a56,57
> 
> auth required pam_google_authenticator.so grace_period=300
" | patch /etc/pam.d/sshd




# HARDENING

echo "
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true

install usb-storage /bin/true

install dccp /bin/true
install sctp /bin/true
install tipc /bin/true
" > /etc/modprobe.d/hardening.conf

mount | grep -E '\s/tmp\s' || echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab && mount /tmp
mount | grep -E '\s/var/tmp\s' || echo "tmpfs /var/tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab && mount /var/tmp

echo "
Defaults use_pty
Defaults logfile=\"/var/log/sudo.log\"
" > /etc/sudoers.d/hardening

chmod og-rwx /boot/grub/grub.cfg

echo "
kernel.randomize_va_space = 2
fs.suid_dumpable = 0

net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
" > /etc/sysctl.d/hardening

mkdir -p /etc/security/limits.d
echo "* hard core 0" > /etc/security/limits.d/hardening

apt install apparmor apparmor-utils
sed -i 's/^GRUB_CMDLINE_LINUX=.*$/GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"/' /etc/default/grub
update-grub

echo "Unauthorised access to this computer is forbidden.  Activity may be monitored." | tee /etc/issue.net > /etc/issue
chown root:root /etc/issue
chmod u-x,go-wx /etc/issue
chown root:root /etc/issue.net
chmod u-x,go-wx /etc/issue.net

systemctl --now disable rsync


# TOOLS

