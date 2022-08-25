+++
author = "Robert Fletcher"
categories = ["Robrotheram", "home-lab", "remote", "working"]
date = 2018-01-01T16:57:15Z
description = ""
draft = false
thumbnail = "/images/Screen-Shot-2018-01-01-at-16.55.19-1.png"
slug = "remote-working"
tags = ["Robrotheram", "home-lab", "remote", "working"]
title = "Remote Working"

+++


Over christmas I been visiting family and friends so I was away from my house and my small homelab but I still wanted a way to do work / check up on my cluster. Previously I mentioned the vpn tunnel I had setup between the raspberry pi and the webserver hosted by OVH. This allowed me to ssh into the server without exposing my home IP or opening ports since I have a the standard BT home router and who knows how many security holes there are in that device. 

But that setup was fine for occasional login just to check things but the latenscy between several different machienes were taken way longer that I expected so just before I set off I did open up just the ssh and http ports on the router so that I have a more direct connection to my homelab. This is tempoary till I can get a true firewall to replace the bt router. Any suggestions for this send the via twitter @robrotheram, 

Now I have a direct connection I still needed to have a way to replicate the dns so that I can use the internal hostnames ie to get to the gitlab I use gitlab.<domainname>.<internal> so I manaually mapped my home IP to all the domainnames in my laptops host files: 
```
   ip.address gitlab.<domainname>.<internal> elk.<domainname>.<internal> ...
```
Since all the the web address come via the same port and ip there needs to be a redirect on my internal infrustutcture, luckily the same nginx server that handels request comming in from the vpn tunnel can serve requests comming from the BT Router. 

Some stuff I do not want exposed via the webport and want it completly internal or be able to edit documents/files stored on the NAS. This is where a remote desktop be useful. 

There are several systems that can be used xrdp,vnc,nomachine etc except all these need several ports open with the free version of nomachine being the worst since it creates a random port on each connection and I am not going to open all ports on my router thats just stupid. So I restored to a little known remote desktop client called x2go. X2Go is an open source remote desktop software for Linux that uses the NX technology protocol. The main advantage for me is one although it uses the NX protocole it does it though a ssh tunnel so know new ports to open. The setup was rather trivial install the server and client and done it works. 

The server is on the main virual machiene that contains all the experimental stuff I am looking at for example Eclipes CHE (webbased version of eclipse) and netbox (digital ocean project to simply document infrustructer). The desktop enviroment of my choice was XFCE I did give some concideration to MATE but my main reasons were space I wanted the smallest enviroment with enough features. 

Performance has been a bit flacky things like terminal work fine but more graphics heavy things like firefox or atom were very laggy but theroy looking at netop is that I am limmited by my upload speed which is only 0.8Mbs 

So if I upgrade my internet I should have way better performance. 

![Screen-Shot-2018-01-01-at-16.08.17](/images/Screen-Shot-2018-01-01-at-16.08.17.png)

