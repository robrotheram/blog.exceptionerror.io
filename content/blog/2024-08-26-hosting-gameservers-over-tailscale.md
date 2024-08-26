+++
author = "Robert Fletcher"
date = 2024-08-26T22:48:39Z
description = ""
title = 'Hosting Game Servers Over Tailscale'
tags = ["Home", "lab", "Virtual machines", "home-lab"]
thumbnail = "/images/2024-08-26-hosting-gameservers-over-tailscale/featured.png"
slug = "hosting-game-servers-over-tailscale"
+++

A friend of mine came to me with a problem. He had a bunch of games servers that was being hosted internally on a old pc turned into a proxmox server. Currently the way to access these servers was opening more and more ports on the ISP provided router turning the firewall into something resembling swiss cheese. Furthermore being on a home internet connection there was no grantee that the External IP would remain static or be moved onto some form of Carrier grade NAT which would make it impossible for the public to connect to the gameservers. In this post I will document how we solved this using a cheep VPS and tailscale. 

The general approach to solve this problem is first get a public proxy server with a static IP most commonly found in any data-center / cloud provider (Linode, OVH, Hertzner, AWS etc) then we setup a VPN tunnel from this proxy server into the local network of your house finally set some forwarding rules so that connections from the public server will get routed to the game server running in the house. When a normal user wants to play on the server they enter the public IP of the proxy server and they will be unaware that the game server is actually running in your house. This given the flexibility that your house IP can change and users would not know, work behind CGNAT and may result in better performance do to how different ISP talk to each other. (https://en.wikipedia.org/wiki/Peering)


For my friend one of the main requirements I wanted it to be is to make is close to as easy to add new servers with the new VPN setup as it was by just opening ports on the firewall. 


![diagram of network](/images/2024-08-26-hosting-gameservers-over-tailscale/diagram.drawio.svg)


## Tailscale VPN

For the VPN tunnel there are couple of options OpenVPN, tinc, or wireguard. We opted for wireguard, but for wireguard you need to set up public/private key paris and copy across to the various servers that need to use the connection. Or we could use a service that would handle all of this for us and provide some tools over the top of wireguard making things more straight forward. Enter form stage left Tailscale. 

Since we did not want to install Tailscale on every game server running, we create a new server and install tailscale to act as a subnet router. 
>A subnet router is a device that facilitates communication between subnets, which are logical divisions of a larger network. In the context of Tailscale, a subnet router is a device within your tailnet that you use as a gateway that advertises routes for other devices that you want to connect to your tailnet without installing the Tailscale client.

First we enabled Ip forwarding
```
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

We then setup the subnet router to advertise the LAN network over tailscale
```
sudo tailscale up --advertise-routes=192.168.0.0/24
```
Enable subnet routes from the tailscale admin console: 

- Open the Machines page of the admin console.
- Locate the Subnets badge in the machines list or use the property:subnet filter to list all devices advertising subnet routes.
- Select a machine with the subnet property, then navigate to the Routing Settings section.
- Select Edit. This opens the Edit route settings panel.
- Under Subnet routes, select the routes to approve, then select Save.


## Proxy Server 
Now we have the Tunnel using tailscale we can configure the Proxy server. 
Once you got a server we can install tailscale but when bringing the connection up we need to tell it to accept the LAN route we told tailscale to advertise 
```
sudo tailscale up --accept-routes
````
At this point from the proxy server you should be able to access any game server you have running on your LAN. You can verify this simply by pining the game server using the LAN IP e.g 192.168.0.55

Next we need to allow connections coming from the public internet to use this new tunnel we have created. 

There again different ways to do this if you are familiar with linux you could use IPTables/NFTables but we decided to use nginx tcp-stream module which allows us to define all the connections in one simple file which is easier to manage if you are not deeply familiar with linux. 

First install nginx

```
sudo apt-get install nginx 
```

Then we add the connections we want to forward into `/etc/nginx/nginx.conf' Below is a example

```
stream {
    upstream mc_server {
        server 192.168.0.55:25565   
    }

    upstream dns {
    server 192.168.0.166:53;
    }

    server {
        listen 25565;
        proxy_timeout 1s;
        proxy_pass mc_server;
    }

    server {
        listen 53 udp;
        proxy_timeout 1s;
        proxy_pass dns;
    }
}
```
Finally Just restart Nginx `sudo system nginx restart` and everyone can now connect to the minecraft server using the proxy ip. 


## Steam Game servers 7Days2Die

Whilst certain games can work out of the box but we found some games from steam sends the server external IP to be used in the server list feature. Currently this will still show the home external ISP whish was the one of the main reasons we were setting up this proxy server. To solve this issue we need to make the 7Days2Die server to route all its connections through the proxy server so that steam resolves the correct IP. 

You could solve this with a set of IpTable/NFTable rules but I wanted to set it up that my Friend could mange it and easily revert if something goes wrong. 
Luckily for us TailScale has a easy solution "Exit node" 

>The exit node feature lets you route all traffic through a specific device on your Tailscale network (known as a tailnet). The device routing your traffic is called an exit node. There are many ways to use exit nodes in a tailnet.

To set it up it as simple as adding the additional argument to the tailscale client on the proxy server, combined with using the subnet router seen above 

```
sudo tailscale up --advertise-exit-node --accept-routes
```

In the tailscale admin console we added find the proxy-server From the ellipsis icon menu of the exit node, open the Edit route settings panel, and enable Use as exit node.

### Using the exit-node.

For the 7Days2Die server we not going the use the subnet-router but instead we will install tailscale on the server itself. We also need to ensure that Ip Forwarding is setup see the commands in the subnet router for enabling it. 

We now need to tell the server to route all traffic through the exit node. The Exit IP will be tailscale IP starting 10.73.*.* which you can find in the tailscale admin console. We also want to allow access from the LAN so you could still ssh using the local. 

```
sudo tailscale set --exit-node=<exit-node-ip> --exit-node-allow-lan-access=true
```
After a reboot we could launch 7Days2Die search for the server name and it shows up with the proxy server IP and we could connect and play



















