+++
author = "Robert Fletcher"
categories = ["home-lab", "random thoughts", "working", "Go", "Cluster"]
date = 2018-08-11T21:42:39Z
description = ""
draft = false
thumbnail = "/images/small-1.jpg"
slug = "homelab-version-2-now-with-ldap"
tags = ["home-lab", "random thoughts", "working", "Go", "Cluster"]
title = "Homelab version 2 now with ldap"

+++


Over the past week I added a small pc to the network to help massively upgrade the services and simplify the authentication process.

The problem I wanted to solve was that I do not want to run the HP DL380 server 24/7 it's loud and more important consumes 200-300 watts idle rather a lot of power for a server doing nothing. But I do want some key services Git and Scrum management to run 24/7 but on my internal network not on some remote server that I do not control. So time to acquire a new pc that is low power but enough to run several services.

The pc that was chosen to to do the task was a intel nuc. It a small pc but pack a decent punch for its size. It has an Intel® Core™ i5-4250U running at 1.3Ghz but can turbo up to 2.6. It is also packing 8Gb of Ram and a 120GB ssd. Not too shabby and is using way way less power good for my energy bill

![](https://screenshotscdn.firefoxusercontent.com/images/6426fbdc-fbe3-443b-a1d0-b1a4b262a719.png)

So I mentioned services how many am I running? The answer is more than I really need but I like this self hosted stuff so here is the the table

| Service | Description | Home page |
|----------|:-------------|-----------|
| Taiga | Project management / Scrum / kanban. Think Jira but penguin friendly | http://taiga.io/ |
| Git/Gitea | Small Git server written in go lightweight. | https://github.com/go-gitea/gitea |
| Bookstack | Documentation tool like confluence but simple and also penguin | https://www.bookstackapp.com/ |
| remote/Guacamole | clientless remote desktop gateway |https://guacamole.apache.org/ | | Monitoring | Grafana Prometheus setup for metric collection and visualizing| https://prometheus.io/docs/visualization/grafana/ | | Docker | Portainer service, web gui to manage all the docker containers |https://portainer.io/ | | Auth | A Keycloak server with an OpenLdap server | https://www.keycloak.org/ https://www.openldap.org/ |


This webportal is at the frontend a very basic golang web template with some bootstrap niceties to spruce it it up because contrary to popular belief at work I am not a ui developer. The backend to it is also very simple just a few api that saves the portal to a config file. No fuss no database. The one added niciety is that it will also generate Traefik config file. So every service I add to the webpage an associated web rule guests added to the web proxy to route traffic to that service. You well see more when we move onto the network diagram.

All of the services listed above are separated from each other using the power of containers and I am full on that bandwagon. So including the webportal/proxy (I combined traefik and my web portal into one container) I have 18 different docker containers running. There are many different ways to have a containerised setup in part one of the key decisions that need to be made is databases. Several of these services are built around different databases weather mysql or postgres and weather you have one single instance of these databases or in my case you have a database per service. It may not be ideal but until I have my services stabilized I will have a instance per service makes cleanup way easier.

#### Networking:
The second decision is networking. Docker can run on the host network in bridge mode where all containers get an ip from the dhcp server or you run it on dockers own internal network and expose ports for the certain services. Since I am using docker-compose each service gets its own ip space. For example the git service will use the 172.18.0.X with the auth service using 172.19.0.x. All of this is abstracted by docker, I have a docker-compose file per service and with the single command `docker-compose up -d` docker will auto create the network and any storage volumes I need and start the containers in that network. Could not be easier.

#### Authentication:
With all of these services I did not want to mange 8 different user accounts across all of these service which is kinda ironic since I am the only person who will ever use it and probably took longer getting all of this setup then the time to log into the service. Who know I might get repurposed as the network for my own company, future dreams.
As I mentioned in the table above I am using keycloak and openldap. OpenLdap handles the users storage and some logins to services while the management of ldap and the ability to use openid single sign on features is done through Keycloak.
Took a few days of prodding to get users created through keycloak added to ldap. In part caused by my inexperience with ldap and openldap funkyness with how it handles groups. But after a few days and some whisky I got it working. And set up gittea grafana and Taiga to use openid single sign on with keycloak. This did cause my to write a whole plugin for taiga to authenticate against keycloak. Sadly neither portainer or bookstack have openid connectors and I really do not want to touch php no matter how much whisky I drink. So all of the other services use Ldap and Ldaps group member off user filter to allow only certain users access to certain services. Although with one user, me, I start to wonder if all of this is really needed. Fun to learn though.

#### Remote Desktop
One of the service I wanted to explore again is remote-desktop / thin client. Apache Guacamole is the only open source service that can offer connection management to remote desktop. To experiment with some thin client stuff I found this wonderful container that has firefox, XFCE Desktop and a rdp client all running inside a container woop. So on the server I have an isolated desktop environment that a user could fire up and connect through using Guacamole. I have not got the whole automation step working but It's an interesting idea and would save thousands in citrix/Windows licencing costs. 


# The network.
Below you can see the network diagram of my infrastructure I have running. It is seperated into 2 parts. The top is the public cloud and is the VM that is hosted on some data centre in Europe and is where this blog is hosted. These are services that need to be highly available, well highly in a relative sense more available if I decide to just turn off all my servers for some reason.

The bottom part is my home network and is running on several servers in my house, yes I am that strange. The 2 are connected through a vpn tunnel using Tinc you can read more about my Tinc setup in an eariler [post](https://blog.robrotheram.com/2017/03/29/home-lab-project-part-3/)

For certain services I want to access from the outside world can use a custom domain name that the nginx proxy will forward down the VPN tunnel. In my Homelab the vpn gets terminated on a small raspberry pi server on this server is one of my webportal/traefik-router. This router then forwards request to the another instance of the webportal/traefik-router which is running on the intel nuc describe above. This router knows where all the services IP are and will then forward the connection onto the appropriate server.

Is this way convoluted for a small network with a single user. Yes. But there is some meaning in this madness. Currently my internal network is on a single flat network but what I want to do in the future is to separate everything onto separate networks so the devices, openstack cluster, services and the Gateway are all on separate networks. Also having all these hoops for the connection to go through I can add in a load of custom logging and auditing of request.

![Untitled-Diagram-1](/images/Untitled-Diagram-1.png)

So that is the state of my network so far. I some future plans with playing around with kubernetes or Openshift on the openstack cluster along with some form of streaming data processing tool for datascienties but thats some pie in the sky thinking.

