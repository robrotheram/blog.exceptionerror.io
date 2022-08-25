+++
author = "Robert Fletcher"
categories = ["home-lab", "openshift", "Paas", "Caas", "Tutorial", "Robrotheram"]
date = 2018-03-18T21:44:01Z
description = ""
draft = false
thumbnail = "/images/OpenShift-app-development.jpg"
slug = "the-trials-of-setting-up-openstack"
tags = ["home-lab", "openshift", "Paas", "Caas", "Tutorial", "Robrotheram"]
title = "The trials of setting up Openshift."

+++


First of all I should just mention what is openshift for those who are not familiar with it. Openshift is a platform as a service (PaaS). While you can use docker to manage a few containers and tools like docker-compose for services (multiple containers that make up an application, website+ database for example). Things get way way more complex once you have multiple physical hosts and want containers to communicate over it, then add dynamic scaling on top and you wish you never heard the term containerization to begin with. For example here is an example architectural diagram of openshift

![refarch-ocp-on-vmw-1](/images/refarch-ocp-on-vmw-1.png)

Openshift is from Redhat can can be found here https://www.openshift.com/ It has had a couple of versions. The first time I used it back in 2013 for hosting some applications I built for some University work. I used it in part because they had free hosting and at that time I already blew through the free tier of AWS. Any how now they have rebased the platform on the well know containerization platform kubernetes (k8).

##Difference between K8 and Openshift

Openshift adds some nice features on top of a k8 cluster. First is main aim to to manage applications so its user interface is way more easier to understand then k8 for new users who do not want to deal with network and containerization fundamentals just to get their application working. Openshift's UI is almost a click and play rather then a load of command line or YAML config to understand. K8 UI is fine for managing applications in a devops situation but if you want to have a team to manage the infrastructure and let developers manage the application then Openshift is better.

Below is a diagram of components that are in Openshift with the purple being K8 and the rest is specific to Openshift.

![0-n2dGPTi4tIlyo7Jf](/images/0-n2dGPTi4tIlyo7Jf.png)

For me the biggest was not the UI which is nice but the Software defined networking. In K8 you have to manage this yourself with either custom proxies or invest in one of the cloud providers which I do not want to do. So next how did I set this up.

First if you want to just tryout Openshift they have a quickstart Vm that has everything one one node and takes minutes to setup and use. It is called minishift you can find out more here: https://www.openshift.org/minishift/
I wanted something more, well I have a 100gb of memory server to hand. I wanted a true openshift cluster with a one master one for infrastructure and a worker node. The problem is that most resources out on the web either cator for the minishift instance or are vast pages of documentation of all the settings for setting up a full production grade system with multiple master nodes which is way overkill for me. 

#Lets Build this thing!

The recommended way for installing openshift is to use ansible and there template form here: https://github.com/openshift/openshift-ansible. The problem I found is that multiple sites do not mention the version they are using so you endup running on master and encounter errors such as the script mentioned in the tutorial is now moved. These tutorials are only 6month to about a year old. 

##Prerequisites
So first let's get the prerequisites to get out of the way:
My machines are 
Centos7 minimal
8GB of ram
2 cores.
50gb disk

I am using 4 virtual machines running of my server running libvirt and qemu. I also have a seperate machine (a raspberry pi) thats a small dns server running dnsmasq.

So first add the 4 ip for the host to the dns server (in my case I added them to the /etc/host file). They are named: ocmaster, ocnode,ocinfra and ocnfs. My domain name is alpha.local

Now I went through the standard minimal Centos 7 to setup the machines and made sure I could ping them via there hostname eg. ocmaster.alpha.local 

In my case I do not have a ansible host so I installed that on the ocmaster machine.  due to the version in the yum repo is a bit behind the one needed for openshift I installed it via pip. 
`sudo pip install ansible. `

On this node make sure you can passwordless ssh to all your nodes you want ansible to touch 

##Setting up Ansible
Clone the repo and check out version 3.7
`git clone https://github.com/openshift/openshift-ansible`
`git checkout release-3.7`
Now to create the inventory template that will be used to setup all the nodes. 

`nano inventory/host`
```
# Create an OSEv3 group that contains the masters, nodes, and etcd groups
[OSEv3:children]
masters
nodes
etcd

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=root

# If ansible_ssh_user is not root, ansible_become must be set to true
#ansible_become=true

openshift_deployment_type=origin
openshift_disable_check=memory_availability,disk_availability

openshift_master_default_subdomain=apps.alpha.local

# uncomment the following to enable htpasswd authentication; defaults to DenyAllPasswordIdentityProvider
#openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

# host group for masters
[masters]
ocmaster.alpha.local

# host group for etcd
[etcd]
ocmaster.alpha.local

# host group for nodes, includes region info
[nodes]
ocmaster.alpha.local
ocnode.alpha.local openshift_node_labels="{'region': 'primary', 'zone': 'east'}"
ocinfra.alpha.local openshift_node_labels="{'region': 'infra', 'zone': 'default'}"

```
You can change it to reflect your hosts more documentation can be found on the openshift site https://docs.openshift.org/3.6/install_config/install/advanced_install.html#adv-install-example-inventory-files

In my case I disabled the openshift_disable_check=memory_availability,disk_availability since my hosts are a bit on the small size for a true production cluster. 
Also check the `openshift_master_default_subdomain` which is the base bit of the domain for your applications e.g \<appname>.apps.alpha.local


I would recommend that you switch back to master and run
`ansible-playbook -i inventory/host playbooks/prerequisites.yml`
this will make sure all things are in order.

Now go back to 3.7 
`git checkout release-3.7`

For me I had to edit a file to get it to find the write host for checking if one of the services were up. Not sure why but caused ansible to error out, seems to be due to the default domain not being recognised. anyhow here is the diff,
```
--- a/roles/template_service_broker/tasks/install.yml
+++ b/roles/template_service_broker/tasks/install.yml
@@ -58,7 +58,8 @@
 # Check that the TSB is running
 - name: Verify that TSB is running
   command: >
-    curl -k https://apiserver.openshift-template-service-broker.svc/healthz
+    curl -k https://ocmaster.alpha.local:8443/healthz
   args:
     # Disables the following warning:
     # Consider using get_url or uri module rather than running curl
```

Now you can run the ansible playbook. 
`ansible-playbook -i inventory/host playbooks/byo/config.yml`

If all goes well and you have got your fingers toes and sacrificed a goat to the great sysadmin gods, it will install and you can access your master and log in (admin:admin is default) You should also have a populated registry and you can launch apps. Hooray!
![FireShot-Capture-68-OpenShift-Web-Console-https___192.168.42.53.nip_.io_8443_console_](/images/FireShot-Capture-68-OpenShift-Web-Console-https___192.168.42.53.nip_.io_8443_console_.png)

##Fixing Some network issues


But first you may noticed that when you launch an app and you click on the link to it ie test.apps.alpha.local you notice it does not respond. We need to add a wildcard to the dns server so all \*.apps.alpha.local gets forwarded to the cluster. in dnsmasq this is simple add this line to /etc/dnsmasq.conf `address=/.apps.alpha.local/192.168.0.62` replace the 192.162.0.62 for the ip of the infra node. Now the links will now work :)

##Persistent Volume and NFS
But still one final problem persistent storage does not work we need to created it.
You may notice that we have used 3 out of 4 machines for this cluster the last is for a nfs server. I separated this out due to my inexperience of nfs so not to break the cluster its on a seperate machine. 
The machine is setup in the same way as al the reset. but we need to install nfs. 
`yum install nfs` 
I created a directory and set the permissions
```
mkdir  -p /var/nfsshare
chmod 777 /var/nfsshare
chown nfsnobody:nfsnobody /var/nfsshare
```
the 777 permissions are probably not needed but I was getting some odd permissions errors with openshift trying to access it. this should not be used for anything productions ish or if the internet touches it. 

in /etc/exports add
`/var/nfsshare    *(rw,sync,no_subtree_check,insecure)`
after many hours of experimentation I found these nfs settings work, 
save the file restart nfs
```
sudo service nfs restart
exportfs -a
```

Back in ocmaster. We need to create the Persistent volumes. Now I have not yet worked out how to do this dynamically for each applications so I am just will create a pool of 10 volumes each 5 Gig in size the main template is 

```
#pb-nfs.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteOnce
  nfs:
    path: /var/nfsshare
    server: 192.168.0.63
  persistentVolumeReclaimPolicy: Recycle
```
Then to add it do `oc create -f pb-nfs.yaml`
I just repeated the create command but each time editing the yaml file changing the metadata name. 

Now I have a fully working openshift cluster. 



It took me 2+ days not much sleep and a lot of googling.

