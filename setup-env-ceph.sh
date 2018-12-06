## Define Ceph Nodes
CLASSROOM_SERVER=10.115.173.2
PASSWORD_FOR_VMS='r3dh4t1!'
OFFICIAL_IMAGE=rhel7-guest-official.qcow2 

curl -o /tmp/open.repo http://classroom/open13.repo
# Define the /etc/hosts file
cat > /tmp/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${CLASSROOM_SERVER}  classroom
EOF


virsh net-update provisioning add ip-dhcp-host "<host mac='52:54:00:01:00:24' name='ceph-mon01' ip='172.16.0.64'/>" --live --config
virsh net-update provisioning add ip-dhcp-host "<host mac='52:54:00:01:00:25' name='ceph-mon02' ip='172.16.0.65'/>" --live --config
virsh net-update provisioning add ip-dhcp-host "<host mac='52:54:00:01:00:26' name='ceph-mon03' ip='172.16.0.66'/>" --live --config
virsh net-update provisioning add ip-dhcp-host "<host mac='52:54:00:01:00:21' name='ceph-node01' ip='172.16.0.61'/>" --live --config
virsh net-update provisioning add ip-dhcp-host "<host mac='52:54:00:01:00:22' name='ceph-node02' ip='172.16.0.62'/>" --live --config
virsh net-update provisioning add ip-dhcp-host "<host mac='52:54:00:01:00:23' name='ceph-node03' ip='172.16.0.63'/>" --live --config

cd /var/lib/libvirt/images/
for node in ceph-node0{1,2,3} ceph-mon0{1,2,3}; do
qemu-img create -f qcow2 $node.qcow2 60G
virt-resize --expand /dev/sda1 ${OFFICIAL_IMAGE} $node.qcow2

virt-customize -a $node.qcow2 \
  --hostname $node.example.com \
  --root-password password:${PASSWORD_FOR_VMS} \
  --uninstall cloud-init \
  --copy-in /tmp/hosts:/etc/ \
  --copy-in /tmp/open.repo:/etc/yum.repos.d/ \
  --selinux-relabel
done


qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph01a.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph01b.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph02a.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph02b.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph03a.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph03b.qcow2 10g



virt-install --ram 2048 --vcpus 1 --os-variant rhel7 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-node01.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph01a.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph01b.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=provisioning,mac=52:54:00:01:00:21 \
--name ceph-node01 --dry-run --print-xml \
> /root/host-ceph-node01.xml

virt-install --ram 2048 --vcpus 1 --os-variant rhel7 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-node02.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph02a.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph02b.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=provisioning,mac=52:54:00:01:00:22 \
--name ceph-node02 --dry-run --print-xml \
> /root/host-ceph-node02.xml

virt-install --ram 2048 --vcpus 1 --os-variant rhel7 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-node03.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph03a.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph03b.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=provisioning,mac=52:54:00:01:00:23 \
--name ceph-node03 --dry-run --print-xml \
> /root/host-ceph-node03.xml

virt-install --ram 2048 --vcpus 1 --os-variant rhel7 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-mon01.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=provisioning,mac=52:54:00:01:00:24 \
--name ceph-mon01 --dry-run --print-xml \
> /root/host-ceph-mon01.xml

virt-install --ram 2048 --vcpus 1 --os-variant rhel7 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-mon02.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=provisioning,mac=52:54:00:01:00:25 \
--name ceph-mon02 --dry-run --print-xml \
> /root/host-ceph-mon02.xml

virt-install --ram 2048 --vcpus 1 --os-variant rhel7 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-mon03.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=provisioning,mac=52:54:00:01:00:26 \
--name ceph-mon03 --dry-run --print-xml \
> /root/host-ceph-mon03.xml


## Create Ceph VMs
virsh define /root/host-ceph-node01.xml
virsh define /root/host-ceph-node02.xml
virsh define /root/host-ceph-node03.xml
virsh define /root/host-ceph-mon01.xml
virsh define /root/host-ceph-mon02.xml
virsh define /root/host-ceph-mon03.xml

## Start Ceph VMs
virsh start ceph-node01
virsh start ceph-node02
virsh start ceph-node03

virsh start ceph-mon01
virsh start ceph-mon02
virsh start ceph-mon03
