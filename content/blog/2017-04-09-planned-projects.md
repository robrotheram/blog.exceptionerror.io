+++
author = "Robert Fletcher"
date = 2017-04-09T22:12:05Z
description = ""
draft = false
image = "/images/start-up-wall-carousel1.jpg"
slug = "planned-projects"
title = "Planned Projects"

+++


Over the next few months there are several projects I want get started to explore several new technologies from new languages to Cluster Architecture technologies with some machine learning in top. I have broken the new technologies into 3 separate projects each one covers something different. These projects are listed below. 


###### Microstack a Golang/React Project 

The first is a project called Microstack. It will be a GoLang/React project, GoLang for the backed serveries and shedding and API creation with a React front-end visualisation and interacting with the API. My plan is to create a web-based version of virt-manager or a stripped down version of open-stack. There are several projects that is a web manager for a virtualisation server but for me the UI is over complicated or is missing some feature, Also I like to add in the Cloud-init scripts to allow the use of cloud-images. Below is a work in progress idea for the frontend currently just using plain html.
![](/images/chrome_2017-04-08_01-28-45.png)
---
######Sentiment Analysis 

The next project I like to get started is to start my adventure into machine learning with some sentiment analysis. Thanks to the Gamealtion IRC Chat and a Logstash bot (Which I might explain in another post) I grabbed over 8.7K messages over a week most surrounding a minecraft server but with other topics mixed in. I have no real plan except to experiment with several tools and try and generated some useful visualisations. If things go well I will experiment with trying to do it in near real time, although I don't know how well it will work judging on a sample of the 8.7k messages I scanned through .Below is a example of some of the messages I collected. 

```json
 {
  "nick": "User1", 
  "message": " meow"
 }, 
 {
  "nick": "User2", 
  "message": "well I might try and get the monitoring code working again and detect \"bad players based on behaviour and kick them if they are doing something bad\" although this sounds like to much work and I will just go back to watching trains "
 }, 
 {
  "nick": "User2", 
  "message": "or be the first to die in the great war either way I fine with"
 }, 
 {
  "nick": "User3", 
  "message": "Speaking of, think I'll watch Westworld. The HBO series is amazing, but I haven't seen the original movie yet."
 }, 
```
---
###### Cluster  Architecture

The final thing I want to investigate in the next 3 months are some cluster architecture designs focusing on the Kubernetes Platform but not limited it, I also want to look into Big Data deployments such as Hadoop Spark being deployed on a Kubernetes platform and see how it compares to a straight virtual machine implementation of a Hadoop Cluster. My main problem is for projects like this I need a idea to from the main bit of the project around. So far I do not know what type of data I want to store on the cluster to test the analytics components. 

![](/images/workflow_k8s_all.png)

