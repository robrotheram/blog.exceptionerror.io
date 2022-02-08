+++
author = "Robert Fletcher"
categories = ["home-lab", "Virtual macheines", "Cluster", "Go"]
date = 2018-05-03T21:55:23Z
description = ""
draft = false
image = "/images/small.jpg"
slug = "https-proxies-and-a-little-bit-of-golang"
summary = "its spring time to clean the server, setup openstack and sort out the mess of nginx configs"
tags = ["home-lab", "Virtual macheines", "Cluster", "Go"]
title = "Homelab part 5: Openstack, proxies and a little bit of golang"

+++


Its spring and like every good person it's time for a spring clean and while my desk is still as cluttered as it always has been,  the home lab has been reset and time to play with some new projects.

Last year I bemonded the size and complexity of setting up openstack for a single node and while I tried to make something that would configure libvirtd and qemu it was a bit overkill of a project. So instead I just use libvirtd and the virt-manager gui to configure the server for all the vms I used in my experimentations. It's now a new year and this time I bit the bullet and installed a full openstack pika release. While I tried some tutorial/devstack automated installations they all suffered the problem of being designed for testing in a vm on a developers machine or have complicated ansible templates for installing over a rack filled with nodes. Most got through most of the installation till they buggered up the networking and I would just reboot and reinstall the os. So I went through the manual process of setting up and configuring all the services. Now I have a fully working setup with provider networking (the ability to have internal networks) the only thing I dont have setup is cider for block storage since I do not have another server filled with hard drives to use.

Since I now have a fully working cloud time to move onto a new problem. Every time I setup a new service or tool to play I have to configure nginx dnsmasq and if I want it accessible from outside my house the nginx proxy on the vps to send connects through the tunnel to the lab. So time to automated it!

It's too infrequent to bother with a ansible template if after a week of testing a new project/service I will just tear it down. I also want some web portal that lists what is running to save me remembering the different addresses. So time to build a simple portal in golang, I become quite the fan of this language.

The project HomeLabPortal can be seen on github https://github.com/robrotheram/HomeLabPortal below is a screenshot. As you can see it's not the most pretty of things and the ui is not some javascript new framework thing. Just simple bootstrap . 

But the trick is that in combination with the new proxy https://traefik.io/ this small tool will write the config for it which traefik will auto reload on a file change.
This means that all  I have to do is add the service url and the subdomain I want it to use and it will do the hard bit of writing the configuration file. I then point all dns routes to the portal address and let the traefik proxy handle the routing to the services.

![screenshot](https://screenshotscdn.firefoxusercontent.com/images/dc37f864-ed0e-4770-8c66-cdb309fee9de.png)

This fixes all my internal routing needs but when I am out and about I need some way to view theses services. I could just open up the firewall and forward communications but that would mean exposing my home IP and having to use some form of dyndns since BT likes changing my home ip frequently, maybe they know I doing something out of the ordinary. So in my case I use a nginx proxy out on the public cloud that forwards any *.mydominname through the vpn tunnel back to my lab as seen by the below diagram

![](/images/HomeLabDiagram-3.png)

Now all the routing is complete time to secure it with some good old fashioned https.

My hosted nginx proxy has been a mess of config file for a while now. Every new thing I would just append to the default file. Why not it is only just another 5 lines of config I sort it out later. This did grow to over 300 lines of config for 2 different domains (robrotheram.com and exceptionerror.io) having a gallery this blog and a nextcloud instance plus routing traffic to my home lab, this has to be fixed.

First I downloaded the config so I could use a visual text editor and created new separate config files for the blog, gallery, nextcloud and my homepage http only. After I verified that they all have were still working  I can move on to getting HTTPS working

My HTTPS certs are from letsencrypt that provides an automated and free certificate renewal process. One of letsencrypt  clients,  certbot has  now  updated to fully support nginx configuration, excellent! 

I downloaded and installed certbot for nginx. Install guide: https://certbot.eff.org/lets-encrypt/ubuntuxenial-nginx

Running it generated new https certificates updated the config files to add the certs and configure redirects from http to the https sites, now all my sites are https secured and will be way easier to maintain then the manual letsencrypt method.

With the web portional of my sites now using https time to move onto the last port forwarding any subdomain to my lab. Since March 2018 letsencrypt allows for wildcard certs, meaning I now do not need to generate a new cert every time I create a service in my lab. installation is simple provide a dns entry in your domain hosting company dns settings and run the cert command.
```
certbot/certbot certonly --manual \
  -d *.<domain.com>  \
  --agree-tos \
  --manual-public-ip-logging-ok \
  --preferred-challenges dns-01 \
  --server https://acme-v02.api.letsencrypt.org/directory
  ```
 
 ```
 server {
    server_name *.exceptionerror.io;
    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
        proxy_pass http://vpntunnelip
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/exceptionerror.io/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/exceptionerror.io/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
 ```
We have the correct cert lets add that to the final part of the nginx configuration and Huzzah! working https termination of all communication to my homelab through the vpn tunnel.

Not bad for a bit of server spring cleaning.

