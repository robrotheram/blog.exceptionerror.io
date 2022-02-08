+++
author = "Robert Fletcher"
categories = ["Home", "lab", "Github", "Robrotheram", "Gitlab", "home-lab"]
date = 2017-03-29T00:00:48Z
description = ""
draft = false
image = "/images/Wikimedia_Foundation_Servers-8055_13.jpg"
slug = "home-lab-project-part-3"
tags = ["Home", "lab", "Github", "Robrotheram", "Gitlab", "home-lab"]
title = "Home Lab Project Part 3"

+++


Its been over a week since the last update to the home lab so below is the following changes that I have made and some experiments with VPN tunnels Below is the network diagram of the lab so far, to make the diagram more simple I have removed the power component (see [part 1](https://blog.robrotheram.com/2017/03/13/my-home-lab/) for the full diagram)

![](/images/HomeLabDiagram--1-.png)

We will ignore the OVH VM for the moment which I will explain in a bit. The main physical infrastructure has not changed since I am happy with it although I would like a new managed switch and a UPS to complete the lab. In the past week I started to experiment with different services, The script found in [part2](https://blog.robrotheram.com/2017/03/16/home-lab-part-2/) makes quickly spinning up VM's so much easier and I have not got into cloud-init customisation yet. A minor change to the script was if I was creating multiple vms the code that generates the mac-address uses entropy from /dev/urandom and can get used up so I am now repleising the entropy using the command `rngd -r /dev/urandom` which makes the script more reliable

The service I have created and are running on the infrastructure is a Gitlab/Mattermost server, a web irc client using a node server called the [The Lounge](https://thelounge.github.io/) and Dev workstaion. All using the base 16.04 cloud image as a starting point. The Dev workstation has the ubuntu mate desktop and a NoMachiene server running on it. Thought I try out [NoMachiene](https://www.nomachine.com/)  I used it a year ago at a previous company for development and it seemed to work well enough and I was not happy with windows -> Linux RDP support also NoMachiene supports copy and paste. I got some performance issues with it not sure if its because it is in a vm on server so the machine has no gpu acceleration or its purely networking. That Layer 2 switch only can do 100mbs so a new switch would give me Gigabit connectivity.

Gitlab/Mattermost setup went just fine using the Gitlab omnibus package so could not be easier. The Last VM is running The Lounge, a IRC web based client I am trying and kinda like. It is still missing auto away feature, if you close a tab the server does not know you have left which is kinda annoying but the benefit is that when you come back it has the full chat logs so you can easily recap the conversation.


Now that I have some services running internally I would love to see them when I am outside my house. The problem is I do not want to expose my home IP address to the internet buy and configure firewalls deal with DDOS protection, and setup some dynamic DNS resolver since I am not paying for business internet. Solution VPN, I currently have a small VM hosted by OVH that runs most of my web stuff homepage gallery this blog etc.

All I need to do is setup a vpn tunnel from my internal network to the OVH VM and make sure either side can ping each other. After abit of research I found that [Tinc VPN](https://www.tinc-vpn.org/) was what I needed, from there site: "its a self-contained VPN solution designed to connect multiple sites together in a secure way", perfect!

I am not going to go through the setup here since all I did was follow this tutorial by smartystrees which can be found here: https://smartystreets.com/blog/2015/10/how-to-setup-a-tinc-vpn

Below is a diagram of how things are connected. On either side of the vpn tunnel is a Nginx proxy that handles the routing. Anything to certain sub-domains get forwarding down the tunnel to the other nginx proxy. I can then add tight restrictions and firewalls to only allow the services I want to be exposed.    
 
![](/images/HomeLabDiagram-3.png)

Now I can expose what ever service I want so I can view it when I am not in my house not sure how useful it be but it was a fun learning experience. That is all for now. Next thing I want to look at is the GO language or automation tools.

