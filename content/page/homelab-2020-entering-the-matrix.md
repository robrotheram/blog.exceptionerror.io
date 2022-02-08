+++
author = "Robert Fletcher"
categories = ["matrix", "element", "home-lab", "server", "self hosted"]
date = 2020-12-11T22:37:07Z
description = ""
draft = false
image = "/images/splash-825x467.jpg"
slug = "homelab-2020-entering-the-matrix"
tags = ["matrix", "element", "home-lab", "server", "self hosted"]
title = "Homelab 2020 - Entering the  Matrix"

+++


Its the end of 2020 due to all the fun events that caused us all to stay at home, or in my case just business as usual, I been tasked to add more and more services to my ever expanding homelab (blog post coming soon ).   This has caused me to go out and buy a bigger VPS and required me to move the existing services from one server to another. The following is my journey to install matrix on the new server.  My deployment system of choice is Ansible installing docker containers and there happens to be a very well supported Ansible project that does just that. [https://github.com/spantaleev/matrix-docker-ansible-deploy](https://github.com/spantaleev/matrix-docker-ansible-deploy) So it should be as simple as following the install instructions and into the matrix we go? But this is me so nothing is that simple.

{{< figure src="/images/Untitled-Diagram-Page-2.png" >}}

The Ansible playbook will install its own Nginx web server in a container. But I have my own Nginx server handling all the other services I use. You can stop Ansible installing Nginx and manage the configuration and certificates yourself. But what if you want to run both so that you let the matrix install handle its own configuration and certificates while you mange just your own custom config. Well this is how I managed it

The above diagram shows the high level system design that Ansible will deploy. It consists of multiple containers including the Nginx server. After all the containers have been deployed and configured we will need to configure Nginx installed to send traffic to matrix. Of note you can see that in this setup all matix traffic is been forwarded in the same TLS connection. the main Nginx server is just passing on the connection.

Step one is to configure the Matrix Ansible project.  I am not going through the setup of Ansible or the project as there already exists an excellent guide in the repo but below are the configured host_vars to allow us to do this crazy forwarding

```YAML
# The bare domain name which represents your Matrix identity.
# Matrix user ids for your server will be of the form (`@user:<matrix-domain>`).
#
# Note: this playbook does not touch the server referenced here.
# Installation happens on another server ("matrix.<matrix-domain>").
#
# If you've deployed using the wrong domain, you'll have to run the Uninstalling step, 
# because you can't change the Domain after deployment.
#
# Example value: example.com
matrix_domain: exceptionerror.io

# This is something which is provided to Let's Encrypt when retrieving SSL certificates for domains.
#
# In case SSL renewal fails at some point, you'll also get an email notification there.
#
# If you decide to use another method for managing SSL certifites (different than the default Let's Encrypt),
# you won't be required to define this variable (see `docs/configuring-playbook-ssl-certificates.md`).
#
# Example value: someone@example.com
matrix_ssl_lets_encrypt_support_email: 

# A shared secret (between Coturn and Synapse) used for authentication.
# You can put any string here, but generating a strong one is preferred (e.g. `pwgen -s 64 1`).
matrix_coturn_turn_static_auth_secret: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# A secret used to protect access keys issued by the server.
# You can put any string here, but generating a strong one is preferred (e.g. `pwgen -s 64 1`).
matrix_synapse_macaroon_secret_key: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

matrix_bot_matrix_reminder_bot_enabled: true

# Adjust this to whatever password you chose when registering the bot user
matrix_bot_matrix_reminder_bot_matrix_user_password: "XXXXXXXXXXXXXXXXXXXXXXXX"

# Adjust this to your timezone
matrix_bot_matrix_reminder_bot_reminders_timezone: Europe/London

#nginx ports
matrix_nginx_proxy_container_http_host_bind_port: '1280'
matrix_nginx_proxy_container_https_host_bind_port: '12443'

```

The key bits of the configuration are: **matrix_domain** this the root domain of the server as will be the name seen in matrix chats ie name@exceptionerror.io but more importantly it will create the following subdomains:

* element.exceptionerror.io
* matrix.exceptionerror.io

Also of note is that we have set the http and https ports to 1280 and 12443 this is so that the matrix nginx does not conflict to the main nginx server.

Now we can run the ansible and if it works we will see a number of container for matrix

```
163927e10734   matrixdotorg/synapse:v1.23.0                           
531c42bb82e1   nginx:1.19.5-alpine                                    
450efd15bb11   ma1uta/ma1sd:2.4.0-amd64                               
6630210dda02   vectorim/element-web:v1.7.15                           
fddfb17ae8b8   instrumentisto/coturn:4.5.1.3                          
a9c8c20fbe29   anoa/matrix-reminder-bot:release-v0.2.0                
d3b0297ce3fa   postgres:13.1-alpine                                   
2661019a64e6   devture/exim-relay:4.93.1-r0                           
```

But if we try and go to element.exceptionerror.io we will get a 404. This is because the main nginx currently does not know how to route to the matrix-nginx-server.  To configure this we can take use of a feature in later versions of NGINX called SNI routing.  The below config will handle all the fowarding. As you can see there is not termination happening or certs to configure. Nginx is just looking at the domain and forwarding it onto the right server

```
stream {

    map $ssl_preread_server_name $name {      
        #matrix
        matrix.exceptionerror.io https_matrix_backend;
        element.exceptionerror.io https_matrix_backend;
        dimension.exceptionerror.io https_matrix_backend;

		#local domains
        robrotheram.com local_https_backend;
        blog.robrotheram.com local_https_backend;
        gallery.robrotheram.com local_https_backend;
        exceptionerror.io local_https_backend;
        watch2gether.exceptionerror.io local_https_backend;
    }


    upstream https_matrix_backend {
        server 127.0.0.1:12443;
    }

     upstream local_https_backend {
       server 127.0.0.1:8443;
    }

    server {
        listen 0.0.0.0:443;
        proxy_pass $name;
        ssl_preread on;
    }
}
```

Now if you go to element.exceptionerror.io it will work Huzzah.  I can create an account 😀. Create and join rooms on the server 😀 but when I try and join a room from another server I get a federation error 😞

Matrix has a lovely federation debugger [https://federationtester.matrix.org/](https://federationtester.matrix.org/) that can query your server and tells you what going on. When I tried this it was getting some odd errors around MatchingServerName and certificates. After a lot of head scratching it came to me. Federation looks for a file at root-domain/.well-known/matrix/server since my homeserver is exceptionerror.io but all matrix calls should hit matrix.exceptionerror.io We need to tell matrix that the server is on a different domain,we dop this by setting some config in .well-known/matrix/server file. For me this just requires a extra path added to the exceptionerror.io root domain

```
location /.well-known {
	return 301 https://matrix.exceptionerror.io/$request_uri;
}
```

This little cheat will make any requrest from matrix will redirect to the right domain and with this 3 lines change federation was working and I can finally dive into all the matrix rooms.

I hope this helps anyone who comes across it or more likely myself in a years time when I need to work how what the hell I did.



