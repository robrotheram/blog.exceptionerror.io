+++
author = "Robert Fletcher"
categories = ["Cluster", "Robrotheram", "data science", "big data", "portal", "hadoop", "spark", "kubernetes", "monitoring", "services", "docker", "rancher", "home-lab"]
date = 2017-08-18T15:54:52Z
description = ""
draft = false
image = "/images/Untitled-design-2.jpeg"
slug = "infrastructure-update-rancher-kuberneties-and-big-data"
tags = ["Cluster", "Robrotheram", "data science", "big data", "portal", "hadoop", "spark", "kubernetes", "monitoring", "services", "docker", "rancher", "home-lab"]
title = "Home Lab Project Part 4:  Rancher, Kubernetes and Big Data"

+++


Its been a while since I last did a update on the current infrastructure. Firstly there has been no major hardware changes. The HP server still runs libvirt managed QEMU Virtual Machines, and all is working well. The main change is that I finally have some new services deployed in to these virtual machines. 

Before I start here is the overview diagram of the current architecture with the focus on the HP Server (Grey Box) There is one main over-arching network (in blue) But the kubernetes cluster has its own internal network that links all the containers together that gets exposed by the loadbalancers (blue diamond)
![](/images/Untitled-Diagram.png)

####Big Data Cluster
This cluster will primarily be used as an learning environment to test various Big Data tools, mainly focusing on streaming pipelines using spark and Kafka. But also to learn how to do some Hadoop bulk processing tasks once I have some data to play around with.

######The Setup
The setup of this cluster was remarkably straight forward and anyone who want to be able to play around with these big data tools can easily set on up. All you need is a machine with enough memory, a small cluster like mine only needs 24GB I went a little overboard.

I provisioned 4 new Ubuntu Server 16.04 virtual machines. The master server has 8 cores 16 GB of RAM, the other 3 virtual machines have only 4 cores and 10GB of RAM since they have fewer services running on theme.

After creating the VMS I made sure that there hostnames matched the domain names that I created in the small dnsmasq server I have running on my network. I installed the Cloudera Manager script and followed the instructions. The Script did everything else; downloading all the services, configuring them and starting them. The UI also does health checks on all the services 

With Cloudera manager setup and monitoring the cluster I can play around with adding data to the HDFS Cluster and experiment around creating spark jobs which will be fun.

####Kubernetes
First what is kubernetes?
It is an open-source system for automating deployment, scaling, and management of containerised applications. It groups containers that make up an application into logical units for easy management and discovery. It developed in-part by google based on their internal platform called Borg.

It has gotten a lot of press and has become the defacto standard for managing cluster of containers. There are other solutions such as MESOS or SWAM but for any production setup will not be cheep to create. Kubernetes is free and there are a lot of other projects that are building on-top of it for there own platform. One example would be Openshift that have migrated to it and have added some openstack components for managing network and authentication making it multi tenanted

######Starting the Cluster 

My initial poke at this technology was using the minikube VM that just created a demo cluster on one machine. This was enough to poke at and go "ooh this is nice".But I not the kind a person to stop at just a single VM. I need a cluster!

So lets try and make a cluster:
 Ubuntu has their own Kubernetes release that can be provisioned through JUJU since I am using bear metal (well VMs) not a cloud provider. While JUJU can do bear metal it sets up a load of LXD containers and I found it impossible to get the networking right to be able to communicate with the cluster out side of the physical host. So I gave up on this method of creating a cluster and moved on to an alternative, although the LXD bit looks very interesting, I need to revisit it when not trying to create a crazy cluster. 

New attempt: Kubernetes have a setup script for setting a small cluster with libvirt. It comes with many caveats and should not be used in production is only for testing network communications so for my needs sounds perfect. Problem was the script was a bit flaky and would set up its own internal Network between the VM leading back to the same problem as the first attempt, i.e not having access outside of the physical host. 

No matter attempt 3: Doing a manual install on 2 new Virtual machines mainly following this tutorial: https://medium.com/@SystemMining/setup-kubenetes-cluster-on-ubuntu-16-04-with-kubeadm-336f4061d929 huzzah I have a cluster. Using Node-Port I can now access the containers outside of the cluster. But one of the advantages Kubernetes has is the service orchestration and auto scaling and load-balancing of the services. If I wanted a web-gui for docker there are plenty of better ways of going about that. When trying to create a load-balancer I ran into all sorts of crazy issues with sometimes the container not starting, not getting the correct port and more importantly no external IP. This is because Kubernetes really wants to be deployed in a cloud environment either AWS,Google-Cloud, or if on prem something like Openstack. 

So 4th and final attempt: When seraching around the net for information about deploying  Kubernetes was a company called Rancher. When I first found them my reaction was, "oh no not another deployment tool I do not want another tool to learn and configure to get working", I just want a small Kubernetes cluster. But I went back and had a look and gave it a try (It helped I found there main getting started documentation that was missing on their homepage)

The install was simple. On a machine that not part of the cluster, install docker and run their server conatiner and on the host you want to manage do the same but use a command the server gives you that points the new hosts to the rancher server. Joys! A simple tool to manage deployments. Rancher can deploy more than Kubernetes, it can deploy a mesos kafaka a Docker swarm cluster. 

Now I have a working Cluster setup can I get it to expose on to my local lan so I can use a service outside of the physical host. I Ran through the example GusetBook example on Kubernetes repo (https://github.com/kubernetes/examples/blob/master/guestbook/README.md) with a small change to the frontend-service.yaml changing `type: NodePort ` to `type: LoadBalancer` After a deploying it to the cluster and a quick cup of tea later I can see that all the containers are working and the service has a exernal ip that matches the host lan ip, yay! When I connect to it does it work? NO why is nothing simple after digging around some forums and slack channels I found the issue was that rancher does all the networking outside of the container using a ton of IPTABLE Rules so I could use the IP from inside the host the container was on but not outside of the host, very strange. I walked through the rules and found that it was not using the external interface, so some simple rules later to forward traffic from the external interface to the internal docker interface and huzzah! a working external service.
 
For note here are the 2 rules, your interfaces may be different 
```
sudo apt-get install iptables-persistent; \
sudo iptables -A FORWARD -i docker0 -o ens3 -j ACCEPT ; \
sudo iptables -A FORWARD -i ens3 -o docker0 -j ACCEPT; \
sudo dpkg-reconfigure iptables-persistent
```

So 4 attempts over a week I now have a cluster, Next who knows but its nice I have some it ready to deploy some containers on in the future. 

#### Other Services

Along with the 2 clusters on the system I also spent some time migrating some of the other services around. An old gitlab virtual machine was retired so I can moved gitlab to a new container running on a single virtual machine where most of the other services are running. This also includes the rancher server that is managing the Kubernetes Cluster.

On this VM I also have a rocket chat instance and playing around with some project management tools things like phabricator or Taiga.io. This brings the container count on this server upto 11. To manage these containers services I added portainer running in a container 

The resulting of all theses virtual machines and containers my infrastructure and my mind looks more like this animation

![](/images/docker.gif)

#####Lets Monitor all of this
My monitoring setup is rather simple, I am using Prometheus Database with metric scraping service. This scrapes metrics from all the node exporters that are installed on each of the virtual machines in the cluster. Extra metrics are provided by Kubernetes and a cAdvisor docker container sitting on the Service virtual machine 

With the metrics collected we need to visualise them, this is where Grafana dashboard server comes in. Connecting it up with Prometheus and using some pre-made dashboards that you can find on their site I can make some very useful graphs which you can see below.

![DHd5hT-XsAASjnN](/images/DHd5hT-XsAASjnN.jpg)

![DHd5hV_XYAAHfIj](/images/DHd5hV_XYAAHfIj.jpg)


The final part is with all the services created I really do not want to remember all the IP and port combinations. So I created a little portal that has some core dials from the monitoring server, links to all the services on my network and for that extra portal goodness a feed from hacker news. 

![DHd6lgvXgAA_e_C](/images/DHd6lgvXgAA_e_C.jpg)

