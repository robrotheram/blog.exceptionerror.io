+++
author = "Robert Fletcher"
categories = ["Projects", "ELK", "Cluster", "Robrotheram"]
date = 2017-07-15T22:12:38Z
description = ""
draft = false
image = "/images/user_23708_58862f1c2ca61.jpg"
slug = "elk-stack"
tags = ["Projects", "ELK", "Cluster", "Robrotheram"]
title = "ELK Stack"

+++


The main work here was looking at how hard it was to setup a ELK stack for metric collection and was where I was storing the IRC data before closing the doors on that project for the moment. 

For me that are lots of great things to say about using a ELK stack for metric collection and processing log files form all small different data sources. I can see why it has become the almost de facto standard for this type of work, It was trivial to set up the initial database and Kibana dashboard. The challenge was getting data data to it and using Logstash to correctly parse it.
 
The getting data to it was mainly in the network setup ([see here](https://blog.robrotheram.com/2017/03/29/home-lab-project-part-3/)) I have to work out how to get the remote vps to send it all its logs. This was mainly a mixture of iptable rules on several machines for elastic to get the data.  
The Logstash config for configuring rules and parsing data takes some time to get the subtlety of the steps it does for each line in the log file that it gets. But after a week of prodding it I was happy with the results I was getting out of it.

![](/images/Screen-Shot-2017-04-10-at-13.35.30.png)

Still  have several architectures I want to play with, Again If I have time I want to try a completely containerised HDFS Spark setup using some orchestrated system, my current idea is [Apache Mesos](https://mesosphere.com/) or [kubernetes](https://kubernetes.io/)

