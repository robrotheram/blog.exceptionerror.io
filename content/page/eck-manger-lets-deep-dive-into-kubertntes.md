+++
author = "Robert Fletcher"
date = 2020-06-20T21:10:12Z
description = ""
draft = true
image = "/images/1-HXdNCVY9Mhx_gWyYIBjKow.jpeg"
slug = "eck-manger-lets-deep-dive-into-kubertntes"
title = "ECK Manger, Lets Deep dive into Kubernetes CRD's"

+++


Kubernetes has always been on my list of topics that I wanted to do a deep dive in. I have already experimented around with building my own clusters. See my experiments with openshift 3.11 here [https://blog.exceptionerror.io/2018/03/18/the-trials-of-setting-up-openstack/](__GHOST_URL__/2018/03/18/the-trials-of-setting-up-openstack/) and later with rancher [https://blog.exceptionerror.io/2017/08/18/infrastructure-update-rancher-kuberneties-and-big-data/](__GHOST_URL__/2017/08/18/infrastructure-update-rancher-kuberneties-and-big-data/) But although I set up clusters I have have not experimented with deploying any major application into the cluster.  But with the recent lockdown and Elastic releasing their cloud on K8 coming out of beta I though it was a perfect time to kill these 2 birds with one stone and lets deep dive into managing a K8 cluster. 

When ever I am learning a new topic I like to have a project to attach to it, I find I learn more when trying to build something then just following a tutorial or course, I usually run into odd caveats that a tutorial / course will mostly avoid. So what the project? Well Elastic Cloud on K8 has no management UI unlike there Elastic Cloud Enterprise project, so lets build one for K8. I mean how hard can it be?

The core requirements I wanted the application to have was to have some form of deploying multiple clusters and group them together with a overarching set of resource limits. With these requirements It requires a number of K8 concepts, Namespaces, Resource limits Secrets, and Ingresses proxies. I also wanted to experiment with RBAC (Role base access control) by giving users different permissions within the project, something the even elastic commercial product lacks

### Elastic Cloud on Kubernetes (ECK)

ECK is built on the Kubernetes Operator pattern which allows Kubernetes own orchestration tool to manage the setup and management of Elasticsearch, Kibana and APM Server.

ECK will make managing and monitoring multiple clusters easier by:

1. Scaling cluster capacity up and down
2. Changing cluster configuration
3. Scheduling backups
4. Securing clusters with TLS certificates
5. Setting up hot-warm-cold architectures with availability zone awareness

What ECK does not have is an UI for managing all of these services its all done via kubernetes YAML with Elastic's own CRD references.

Below is from ECK quick start guide and its for deploying just a single node Elasticsearch cluster with no extra configuration. These YAML's can get rather large and cumbersome once you want multiple nodes, custom configuration and apply resource limits.

```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.8.0
  nodeSets:
  - name: default
    count: 1
    config:
      node.master: true
      node.data: true
      node.ingest: true
      node.store.allow_mmap: false
```

That was the main reason I wanted to attempt to build a UI so people unfamiliar with K8 syntax could design a deployment and launch it into a K8 Cluster.

### ECK Manager Application

The ECK UI I developed is written in Go with a React frontend using elastic own UI framework, this post will not touch on the frontend but all the code can be found here: [https://github.com/robrotheram/eckmanager](https://github.com/robrotheram/eckmanager) Most of the code snippets in this post will be from the repo

The backend Go code uses the K8 dynamic client to interface with the k8 cluster this was chosen over the static client because the static client does not have the support for elastic CRD spec therefore the backend will need to build up compatible JSON requests to send to the k8 cluster.













{{< figure src="/images/deployment.png" >}}











{{< figure src="/images/deployment-create.png" >}}

