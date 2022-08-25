+++
author = "Robert Fletcher"
categories = ["home-lab"]
date = 2017-03-13T17:03:30Z
description = ""
draft = false
thumbnail = "/images/Wikimedia_Foundation_Servers-8055_13.jpg"
slug = "my-home-lab"
tags = ["home-lab"]
title = "Home Lab Project"

+++


My new project for the past months and for the next few months is the construction of my home lab. The purpose of this lab is to learn some new technologies that I could not with using a hosted solution as I did for the past 3 years using a server from OVH. 

The Diagram below shows the current state of my little lab that been made up from some scavenged components form old companies hardware that was planned to be scrapped and stuff from eBay. 
![](/images/HomeLabDiagram.png)

Lets start a the beginning, (I have been told its a very good place to start), the internet comes into a standard ISP router that provides WiFi and basic DHCP. That connects to a basic D-link 24 port switch. off that switch is a small 4 port remote PDU. The main reason for the PDU is that most of this hardware lives in a small cub-board under the stairs, and I am too lazy to crouch down and turn on/off the servers when I need them. The servers are not planned to be run 24/7 only when I need to do something so its nice that from the workstation or from a phone connected to the network to turn on the servers without bending down. 

Most of the devices on the network will be controlled by a Windows PC. The workstation is a custom desktop  built PC with a Intel i7 with 16GB of DDR4 and a Nvidia GTX 970 that will be used for development and ssh to the server and Virtual machines running on it. Thank god for WSL (Windows Subsystem for Linux). The ability to with a couple of shortcuts to type ssh to get any Linux computer. 

I should now mention the servers:
The simplest one is the DNS server which is just dnsmasq running on a raspberry-pi Gen 3.

The R200 server only has 2GB of ram and a old 1.6 4 core processor not sure what to do with it, its noisy and not that powerful currently it runs a gitlab server but that may move to a VM. Not sure what to do with this at the moment.

Finally is a great find on EBay a HP DL380 G7, This is going to be the main workhorse it has 24 cores 100gb of ram and 8x146GB of storage. Currently the storage is configured as 7 drives in a raid 5 with the 8th on standby if one of the drives in the raid dies.

The main areas want to look into largely based in the software infrastructure projects. Mesos cluster, docker swarm, kubernetes etc. Other things is some anylicts data capture in the IOT space. 

![0PVqoxb](/images/0PVqoxb.png)

