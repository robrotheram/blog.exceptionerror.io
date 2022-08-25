+++
author = "Robert Fletcher"
categories = ["Home", "lab", "Virtual macheines", "home-lab"]
date = 2017-03-16T12:03:59Z
description = ""
draft = false
thumbnail = "/images/Wikimedia_Foundation_Servers-8055_13.jpg"
slug = "home-lab-part-2"
tags = ["Home", "lab", "Virtual macheines", "home-lab"]
title = "Home Lab Project part 2"

+++


Time to get some virtual machines running. The main plan is to use Ubuntu cloud images, they are small 300MB approx compared to Centos7 minimal 700MB. The problem with using cloud images is that they are designed to be run in large data center with something like AWS or OpenStack. Since I am running one machine I cant't use OpenStack (its really designed for 3 host or greater) it can be run on a single machine but I don't want to have that overhead to manage.  Thanks to a little utility cloud-localds it can take the cloud-init script bundle it up as a live CD ready for deployment.

For a reference here is the diagram taken from the larger Diagram in [part 1 ](https://blog.robrotheram.com/2017/03/13/my-home-lab/) of the HP server. It has 2 interfaces configured Eth1 and Eth2. Eth1 is a bridge network so VM's on this network is exposed to the rest of the network this will be for public service. the other Eth2 is the box. Also there is the Virsh network Vibr0 which as a internal subnet and is NAT out to the rest of the network. What this means is that any VM on the Virb0 can get out to the internet to get packages etc but no machine on the network can see them.
![](/images/HomeLabDiagram-2.png)
---

##### The Scripts
     
To make my life easier if I need to rebuild my setup I broken the script into 2 parts first will grab all the cloud images I need so I do not have to keep downloading them each time

```bash
echo "Downloading 14.04"

curl https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img -o trusty-server-cloudimg-amd64-disk1.img

echo "Downloading 16.04"
curl https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img -o xenial-server-cloudimg-amd64-disk1.img

echo "Downloading 16.10"
curl https://cloud-images.ubuntu.com/yakkety/current/yakkety-server-cloudimg-amd64.img     -o  yakkety-server-cloudimg-amd64.img
``` Full Version: [getimages.sh](https://github.com/robrotheram/VMCreator/blob/master/getimages.sh)

The second and main part is the create.sh script that does the heavy lifting of generating a default cloud-init script and new ssh key-pairs for each VM. Although you can skip this if you specify a your own cloud init script. It creates a hard disk of the size specified from any of the Ubuntu versions that has been downloaded. Using a little bit of UNIX magic found from [here](https://superuser.com/a/470745) a small one liner mac generation

After the disk has been created along with the cloud utils image we can create the VM using virsh and start it. 

```bash
mkdir -p cloud/$HOST/config

if [ -z "$CLOUD" ]; then
  ssh-keygen -b 2048 -t rsa -f cloud/$HOST/config/sshkey -q -N ""
  key=$(cat cloud/$HOST/config/sshkey.pub)
  cat > cloud/$HOST/config/user_data << EOF
  #cloud-config
  users:
    - name: ubuntu
      groups: sudo
      shell: /bin/bash
      sudo: ['ALL=(ALL) NOPASSWD:ALL']
      password: mypassword
      chpasswd: { expire: False }
      ssh_pwauth: True
      ssh-authorized-keys:
        - $key
    - touch /test.txt
  EOF
  cloud-localds cloud/$HOST/seed.img cloud/$HOST/config/user_data
else
  cloud-localds cloud/$HOST/seed.img  $CLOUD
fi

qemu-img convert -O qcow2 $IMG $DISKIMG_PATH
qemu-img resize $DISKIMG_PATH +$DISK

macadd="00:60:2f"$(hexdump -n3 -e '/1 ":%02X"' /dev/urandom)

virt-install --vnc --noautoconsole --noreboot \
--name $HOST \
--ram $RAM \
--vcpu $CPU \
--disk path=$DISKIMG_PATH,format=qcow2 \
--cdrom cloud/$HOST/seed.img \
--boot=hd --livecd \
--bridge=$NETWORK -m $macadd

virsh start $HOST
```
Full Version [create.sh](https://github.com/robrotheram/VMCreator/blob/master/create.sh)

Annoyingly If I use the bridge network instead of the internal virsh network I can not seem to find the IP of the machine. `arp -e` responds with nothing so I have to manually go to the dhcp router and find it there. If I use the virsh internal network I can just do `virsh net-list default` and find the IP there

