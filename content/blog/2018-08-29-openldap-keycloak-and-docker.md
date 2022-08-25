+++
author = "Robert Fletcher"
categories = ["home-lab", "Authentication", "LDAP", "Keycloak"]
date = 2018-08-29T23:47:06Z
description = ""
draft = false
thumbnail = "/images/cyber-security.jpg"
slug = "openldap-keycloak-and-docker"
tags = ["home-lab", "Authentication", "LDAP", "Keycloak"]
title = "Openldap Keycloak and docker"

+++


Some detail documentation on how I have setup almost single sign-on to Gitea, Taiga.io, Grafana, Portainer and Bookstack using Openldap and Keycloak

This post has spun from this reddit [post](https://www.reddit.com/r/selfhosted/comments/9b5xbc/reaching_out_for_help_with_openldap_and_site/ ) over at r/selfhosted about how to get openldap working with keycloak. While I am no expert it did remind me about the pain it was and so it be a good idea to fully document it somewhere for later reference.

As seen from my previous post https://blog.robrotheram.com/2018/08/11/homelab-version-2-now-with-ldap/ I am running a good number of services that I like to have a single idenity accross all of them and some where near single signon to most.

![](https://screenshotscdn.firefoxusercontent.com/images/6426fbdc-fbe3-443b-a1d0-b1a4b262a719.png)

I am using keycloak as the identity management tool that all the services should hopefully connect to check the identity of the user trying to log in. For the login mechanism I went with openid for 2 reasons one I saw a tutorial about it somewhere and that my first service to try and connect gittea had support for it and not SAML. The problem is that although some of the services listed in that screenshot support openid bookstack and taiga.io and portainer did not but did have LDAP support.

So I will be using LDAP for storing users and then using Keycloak for federating the identity to the services that can support openid. Since I am a fan of docker all of this is in a set of docker containers.

```

    version: '3'
    volumes:
      postgres_data:
          driver: local
      ldap:
          driver: local
    services:
      postgres:
          image: postgres
          volumes:
            - postgres_data:/var/lib/postgresql/data
          environment:
            POSTGRES_DB: keycloak
            POSTGRES_USER: keycloak
            POSTGRES_PASSWORD: *********
      keycloak:
          image: jboss/keycloak
          environment:
            DB_VENDOR: POSTGRES
            DB_ADDR: postgres
            DB_DATABASE: keycloak
            DB_USER: keycloak
            DB_PASSWORD: *********
            KEYCLOAK_USER: admin
            KEYCLOAK_PASSWORD: *********
            #JDBC_PARAMS: "ssl=true"
          ports:
            - 8081:8080
          depends_on:
            - postgres
          volumes:
            - ./themes:/opt/jboss/keycloak/themes/custome/:rw
      openldap:
        image: osixia/openldap
        volumes:
           - ldap:/var/lib/ldap
        environment:
          LDAP_ORGANISATION: "ExceptionError INC"
          LDAP_DOMAIN: "exceptionerror.io"
          LDAP_BASE_DN: ""
          LDAP_ADMIN_PASSWORD: "admin"
          LDAP_READONLY_USER: "true"
          LDAP_READONLY_USER_USERNAME: "readonly"
          LDAP_READONLY_USER_PASSWORD: "*********"
        ports:
          - 389:389
   ```
   So the above the docker-compose will create an openldap container and a keycloak/postgress container. 
   
   I am managing Openldap via Apache Directory Studio https://directory.apache.org/studio/ although something like phpMyLdap would also work. I imported this .ldfs file that sets up some basic users and groups. The groups were the bit that was more important. Openldap has some oddities about auto creating fields so that memberof queries work, more on this later 
   
   
   ```
  version: 1

dn: ou=groups,dc=exceptionerror,dc=io
objectClass: organizationalUnit
objectClass: top
ou: groups

dn: cn=Ensign,ou=groups,dc=exceptionerror,dc=io
objectClass: top
objectClass: groupOfUniqueNames
cn: Ensign
uniqueMember: 

dn: cn=Crewman,ou=groups,dc=exceptionerror,dc=io
objectClass: top
objectClass: groupOfUniqueNames
cn: Crewman
uniqueMember:

dn: cn=Engineer,ou=groups,dc=exceptionerror,dc=io
objectClass: top
objectClass: groupOfUniqueNames
cn: Engineer
uniqueMember:

dn: cn=Commander,ou=groups,dc=exceptionerror,dc=io
objectClass: top
objectClass: groupOfUniqueNames
cn: Commander
uniqueMember:

dn: cn=Mark Cuban,ou=users,dc=exceptionerror,dc=io
cn: Mark Cuban
gidnumber: 500
givenname: Mark
homedirectory: /home/users/mcuban
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Cuban
uid: mcuban
uidnumber: 1002
userpassword: {MD5}ICy5YqxZB1uWSwcVLSNLcA==

dn: cn=Steve Jobs,ou=users,dc=exceptionerror,dc=io
cn: Steve Jobs
gidnumber: 500
givenname: Steve
homedirectory: /home/users/sjobs
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Jobs
uid: sjobs
uidnumber: 1001
userpassword: {MD5}ICy5YqxZB1uWSwcVLSNLcA==

```

Now that we have some users and groups time to get ldap connected to keycloak. Below is the settings I have set up for the LDAP adapter. Since I want keycloak to manage LDAP so users can register or edit their passwords

![Screenshot-at-2018-07-30-23-41-32](/images/Screenshot-at-2018-07-30-23-41-32.png)
   
I also wanted to have certain groups do certain things so in the mappings I have added a group mapping

![Screenshot-at-2018-07-30-23-46-22](/images/Screenshot-at-2018-07-30-23-46-22.png)

The final is to set a full name mapping to map to the CN attribute. 

![Screenshot-at-2018-08-30-00-27-01](/images/Screenshot-at-2018-08-30-00-27-01.png)

I also had to set the READ_ONLY Flag on the last name and Frist name to off. 

Now if all has gone well users should be able to register and then beable to change their password. 

## Setting up OpenID

Below is an example for the settings needed to get openid setup for keycloak

![Screenshot-at-2018-08-30-00-31-08](/images/Screenshot-at-2018-08-30-00-31-08.png)

In gitea you can add an OAuth2 Source as the keycloak 

![Screenshot-at-2018-08-30-00-34-23](/images/Screenshot-at-2018-08-30-00-34-23.png)

-----

## LDAP

Services that cant use openid/OAuth2 will have to fall back to using LDAP but I may want certain services such as portainer only allowed to be accessed by users in the admin group. to do this I need some LDAP query magic and was why the groups were set up in LDAP as `groupOfUniqueNames` was so I can user the ldap query:
`(&(objectClass=inetOrgPerson)memberof=cn=Commander,ou=groups,dc=exceptionerror,dc=io))`
To split it up a user must be of type inetOrgPerson and be a `memberof` the Commander group. In openldap the default setting is to create the memberof mapping for only `groupOfUniqueNames`.

