#!/usr/bin/env bash

set -e

err_msg() {
  echo "FAILED - Error on line $(caller)"
  touch /root/sysprep_failed.txt
} 

trap err_msg ERR

exec >/var/log/cloud-init-output.log 2>&1

rm -f /root/sysprep_*.txt

sleep 10

HN=$(curl http://169.254.169.254/latest/meta-data/hostname)
hostnamectl set-hostname $${HN}${ec2domain}

rpm -q rh-amazon-rhui-client && rpm -e rh-amazon-rhui-client

grep server_timeout /etc/rhsm/rhsm.conf || subscription-manager config --server.server_timeout=360
subscription-manager status || subscription-manager register --activationkey='${rhak}' --org='${rhorg}'
subscription-manager status
subscription-manager repos --disable="*"
subscription-manager repos --enable="rhel-sap-hana-for-rhel-7-server-eus-rpms" --enable="rhel-7-server-eus-rpms"
subscription-manager release --set=7.6

yum clean all
yum update -y
yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct unzip nfs-utils autofs lvm2

sed -i 's/^#compress/compress/g' /etc/logrotate.conf

yum install -y tuned-profiles-sap-hana compat-sap-c++-6 chrony gtk2 libicu xulrunner tcsh libssh2 expect cairo graphviz iptraf-ng krb5-workstation krb5-libs libpng12 nfs-utils lm_sensors rsyslog openssl098e openssl PackageKit-gtk3-module libcanberra-gtk2 libtool-ltdl xorg-x11-xauth numactl xfsprogs net-tools bind-utils

# HANA O/S customizations
systemctl enable --now tuned 
tuned-adm profile sap-hana-vmware
echo "kernel.numa_balancing = 0" > /etc/sysctl.d/90-sap_hana.conf
sysctl -p /etc/sysctl.d/90-sap_hana.conf
systemctl disable --now numad

sed -i -e 's/^\(GRUB_CMDLINE_LINUX=.*\)/#\1/g' /etc/default/grub
sed -i -e '/^#GRUB_CMDLINE_LINUX=/ aGRUB_CMDLINE_LINUX="console=ttyS0,115200n8 console=tty0 net.ifnames=0 rd.blacklist=nouveau crashkernel=auto no_timer_check transparent_hugepage=never"' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

sed -i -e 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

systemctl enable --now chronyd

systemctl disable --now firewalld

ln -s /usr/lib64/libssl.so.1.0.2k /usr/lib64/libssl.so.1.0.2
ln -s /usr/lib64/libcrypto.so.0.9.8e /usr/lib64/libcrypto.so.0.9.8
ln -s /usr/lib64/libcrypto.so.1.0.2k /usr/lib64/libcrypto.so.1.0.2

echo "@sapsys soft nproc unlimited" >/etc/security/limits.d/99-sapsys.conf

systemctl disable --now abrtd
systemctl disable --now abrt-ccpp
systemctl disable --now kdump

cat >>/etc/security/limits.conf <<EOF
* soft core 0
* hard core 0
EOF

DEVICE="/dev/$(lsblk | grep -w disk | sort | tail -1 | awk '{print $1}')"

wipefs -a $${DEVICE}
pvcreate $${DEVICE}
vgcreate sapvg $${DEVICE}
lvcreate -L 20G -n lv_usr_sap sapvg
lvcreate -L 48G -n lv_hana_shared sapvg
lvcreate -L 24G -n lv_hana_data sapvg
lvcreate -L 24G -n lv_hana_log sapvg
mkfs.xfs /dev/sapvg/lv_usr_sap
mkfs.xfs /dev/sapvg/lv_hana_shared
mkfs.xfs /dev/sapvg/lv_hana_data
mkfs.xfs /dev/sapvg/lv_hana_log
mkdir -p /usr/sap
mkdir -p /hana/shared
mkdir -p /hana/data
mkdir -p /hana/log
echo "/dev/sapvg/lv_usr_sap /usr/sap xfs defaults 1 3" >>/etc/fstab
echo "/dev/sapvg/lv_hana_shared /hana/shared xfs defaults 1 4" >>/etc/fstab
echo "/dev/sapvg/lv_hana_data /hana/data xfs defaults 1 5" >>/etc/fstab
echo "/dev/sapvg/lv_hana_log /hana/log xfs defaults 1 6" >>/etc/fstab

systemctl enable --now autofs

echo "COMPLETED"

/bin/cp -pf /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >>/etc/rc.d/rc.local <<EOF
touch /root/sysprep_complete.txt
/bin/mv -f /etc/rc.d/rc.local.orig /etc/rc.d/rc.local
chmod -x /etc/rc.d/rc.local
EOF

chmod +x /etc/rc.d/rc.local

reboot

