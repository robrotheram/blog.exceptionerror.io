+++
author = "Robert Fletcher"
categories = ["Home", "lab", "Github", "Virtual macheines", "home-lab"]
date = 2017-03-17T23:49:17Z
description = ""
draft = false
thumbnail = "/images/Wikimedia_Foundation_Servers-8055_13.jpg"
slug = "home-lab-project-part-2-5-chicken-or-the-egg"
tags = ["Home", "lab", "Github", "Virtual macheines", "home-lab"]
title = "Home Lab Project Part 2.5 Chicken or the Egg"

+++


In My adventures of creating my home lab that's a tiny version of AWS so I can spin up several VMS into a small cluster to experiment with some of the big data tools out there and give them a metaphorical kicking to see what they can do and if the be useful for me. In the [previous post](https://blog.robrotheram.com/2017/03/16/home-lab-part-2/) a created a small script that does the boiler plate work of setting up a vm. Since I am using cloud images I also does the basic OS setup and user creation.

Now should be the fun bit connect to the vm but one problem what IP is it on? I have a mac address and nothing else. If its on the internal network which is handled by virsh then I can grep on `virsh net-dhcp-leases --network default` to find out the IP. But for br0 the only place it is listed is in the DHCP logs of the router but I don't want to log in to it each time I need to find an IP address. for experiments a grep on apr table was too inconsistent. More annoyingly since they are cloud images I cant log into them via VNC since only ssh with a private is the only way, Great !. Time to bring out the trusty hammer approach and machine gun the network by firing out a load of ping packets and wait for the apr table to update itself, I could just wait but who has time for that. 

Below is the final part in the vm-creation script that after the vm is started I search for the mac address in the apr table and if its not there query the network to see if the host is up. 

```bash
echo "Giving time for the network to stabilise"
sleep 10
echo "Querying Network"
while [ -z "$HOST_IP" ]; do
  echo "Waiting ..."
  fping -a -q -g 192.168.0.0/24 > /dev/null 2>&1;
  HOST_IP=$(arp  | grep -i $macadd | awk '{print $1}');
  sleep 2;
done
echo "Host: $HOST | mac: $macadd | IP: $HOST_IP"
```
[create.sh](https://github.com/robrotheram/VMCreator/blob/master/create.sh)

**Cleanup time**

As you could probably imaging trying to get the network to report back the IP I created a few VMS sadly with not that interesting names I was getting a little fustrated my bash skills a a bit basic. 
 
![](https://i.imgur.com/ftl8kTf.png)
When the scripts were done I wanted a nice way in virsh to stop all active vms and delete them. Strangely Virsh did not have such a command or there was not a clever one-liner command I could find searching Google.  No matter my tool box contains many hammers time to break out a sledge hammer. 


```bash
echo "Clean up in progress !"

echo "Shutting down all vm !"
for x in `virsh list | awk '{print $2}' `; do 
virsh destroy $x 2>/dev/null;
done

echo "Now removing them !"
for x in `virsh list --all | awk '{print $2}' `; do
virsh undefine $x 2>/dev/null;
done
```
[Cleanup.sh](https://github.com/robrotheram/VMCreator/blob/master/cleanup.sh)

