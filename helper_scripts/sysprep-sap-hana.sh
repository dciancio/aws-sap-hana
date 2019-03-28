#!/usr/bin/env bash

set -e

exec >/var/log/cloud-init-output.log 2>&1

DEVICE="/dev/$(lsblk | grep -w disk | sort | tail -1 | awk '{print $1}')"

HN=$(curl http://169.254.169.254/latest/meta-data/hostname)
hostnamectl set-hostname $${HN}.${ec2domain}

rpm -e rh-amazon-rhui-client
yum clean all
rm -rf /var/cache/yum

subscription-manager register --activationkey='${rhak}' --org='${rhorg}' --force
subscription-manager status
subscription-manager repos --disable="*"
subscription-manager repos --enable="rhel-sap-hana-for-rhel-7-server-eus-rpms" --enable="rhel-7-server-eus-rpms"
subscription-manager release --set=7.6

yum clean all
yum update -y
yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct unzip nfs-utils autofs lvm2
yum install -y tuned-profiles-sap-hana compat-sap-c++-6 chrony gtk2 libicu xulrunner tcsh libssh2 expect cairo graphviz iptraf-ng krb5-workstation krb5-libs libpng12 nfs-utils lm_sensors rsyslog openssl098e openssl PackageKit-gtk3-module libcanberra-gtk2 libtool-ltdl xorg-x11-xauth numactl xfsprogs net-tools bind-utils

cd /root
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

cd /root
wget https://www.rarlab.com/rar/rarlinux-x64-5.7.0.tar.gz
tar -zxf rarlinux-x64-5.7.0.tar.gz
cd rar
make

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

wipefs -a $${DEVICE}
pvcreate $${DEVICE}
vgcreate sapvg $${DEVICE}
lvcreate -L 20G -n lv_sap_bin sapvg
lvcreate -L 24G -n lv_hana_shared sapvg
lvcreate -L 24G -n lv_hana_data sapvg
lvcreate -L 12G -n lv_hana_log sapvg
mkfs.xfs /dev/sapvg/lv_sap_bin
mkfs.xfs /dev/sapvg/lv_hana_shared
mkfs.xfs /dev/sapvg/lv_hana_data
mkfs.xfs /dev/sapvg/lv_hana_log
mkdir -p /usr/sap
mkdir -p /hana/shared
mkdir -p /hana/data
mkdir -p /hana/log
echo "/dev/sapvg/lv_sap_bin /usr/sap xfs defaults 1 3" >>/etc/fstab
echo "/dev/sapvg/lv_hana_shared /hana/shared xfs defaults 1 4" >>/etc/fstab
echo "/dev/sapvg/lv_hana_data /hana/data xfs defaults 1 5" >>/etc/fstab
echo "/dev/sapvg/lv_hana_log /hana/log xfs defaults 1 6" >>/etc/fstab

systemctl enable --now autofs

reboot

