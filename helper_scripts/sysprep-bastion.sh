#!/usr/bin/env bash

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
subscription-manager repos --enable="rhel-7-server-rpms"
subscription-manager release --set=7.6

yum clean all
yum update -y
yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct unzip nfs-utils autofs lvm2

cd /root
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

cd /root
wget https://www.rarlab.com/rar/rarlinux-x64-5.7.0.tar.gz
tar -zxf rarlinux-x64-5.7.0.tar.gz
cd rar
make

wipefs -a $${DEVICE}
pvcreate $${DEVICE}
vgcreate vg01 $${DEVICE}
lvcreate -L 50G -n lvol01 vg01
mkfs.xfs /dev/vg01/lvol01
mkdir /uploads
echo "/dev/vg01/lvol01 /uploads xfs defaults 0 0" >>/etc/fstab
mount /uploads

echo "/uploads *(rw,async,no_root_squash)" >/etc/exports
systemctl enable --now nfs-server
systemctl enable --now autofs
exportfs -rav

#FILES=( 51053381_part1.exe 51053381_part2.rar 51053381_part3.rar 51053381_part4.rar )
FILES=( SAPCAR_1211-80000935.EXE IMDB_SERVER20_036_0-80002031.SAR )
cd /uploads
for i in "$${FILES[@]}"; do
/usr/local/bin/aws s3 cp --no-progress s3://ddelcian-uploads/$i .
chmod 700 $i
done

reboot

