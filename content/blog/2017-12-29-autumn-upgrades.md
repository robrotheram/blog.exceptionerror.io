+++
author = "Robert Fletcher"
date = 2017-12-29T16:06:59Z
description = ""
draft = false
thumbnail = "/images/Capture-3-1.PNG"
slug = "autumn-upgrades"
title = "Autumn Upgrades"

+++


The nights are drawing in and its getting colder outside the leaves on the trees are changing to that wonderful autumn colour so time for some cluster upgrades. 

Most blogs document the install procedure of thing X but are less likly to document the running of thing X, Yes this is probably not that interesting for anyone but myself to read but as this blog is in part to document work I have done on my own projects it derserves a place here. 

First thing first, cableing, sadly I do not have a nice 12U rack to put the servers in, I live in a rented house and I not sure if my landlord would be best pleased I turned his home into a datacenter (although soon as I have my own house I probably will). So where is the server and networking gear? Well its stuffed into a tiny cupboard under my stairs, next to the gass meter what could possibly go wrong. But with a few cable ties and moving some things around I now have what I going with a tidy setup, Well its tidyer then the other cupboard (lets not go there) 

![IMG_20171024_234522](/images/IMG_20171024_234522.jpg)

Luckly I do not use the server that often so most of the time it and the monitor are off. The only thing running is the remote PDU (hidden at the back of the servers), a pi that you can see on the switch which is a dns server and runs a tunc deamon for vpn comunications. The new addition is the white box, which is a basic sysnology NAS. I could have set one up on the server but I don't really want to burn 250W per hour for occasional data syncing from 2 computers. The synology nas has a nice 2TB hardrive which will server my perpose for now. 

Since I have the server running, time to do some upgrades. Not gonning to bother mentioning the OS (`apt update && apt upgrade -y` done) Instead I am going to mention the upgrade process of the 2 clusters that I am runing; Kubertes and Cloudera.

Cloudera was really simple after loging into the cluster I went to parcels and update the various parcels. When you click update cloudera manager deals with the downloading, distrubitng and activating the update across the cluster.
![Capture-2](/images/Capture-2.PNG)

Kubernetes was a more tricky due to the way I am manerging it with rancher. First was to upgrade the rancher server to get the latest Kubernetes. Thanks to rancher and using docker  there is good example of how to upgrade the cluster 

http://rancher.com/docs/rancher/v1.2/en/upgrading/#single-container

the essentail bits of the commands are the following to convert the current running docker container into a volume so it can exisit between rancher versions.

```
docker stop rancher

docker create --volumes-from rancher --name rancher-data rancher/server:<tag_of_previous_rancher_server>

docker pull rancher/server:latest

docker run -d --volumes-from rancher-data --restart=unless-stopped -p 8080:8080 rancher/server:latest

```

![Capture](/images/Capture.PNG)

After rancher has been upgraded we can check the current kubertes stack and check if we are uptodate. Starting the upgrade process is very simple just click and go. Slight problem was that it felt it took a rather long time (2ish) hours to cycle through all of the containers to upgrade them.

At the moment I am running just the very simple guestbook demo to check things are working. After the upgrade I had to restart all of the application container in kubertes in order for the to see each other. I also had to delete and restore the nginx load balancing service inorder for a user outside of the cluster to access the containers




![Capture-3](/images/Capture-3.PNG)

