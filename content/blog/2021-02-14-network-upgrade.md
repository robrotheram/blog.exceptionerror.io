+++
author = "Robert Fletcher"
date = 2021-02-14T15:04:21Z
description = ""
draft = false
image = "/images/Traffic-SQ1.jpeg"
slug = "network-upgrade"
title = "Home network upgrade to Ubiquiti"

+++


Its 2021 and a lot of changes have happened since I last did a blog post on my home-lab. Something big happened in 2020 which resulted in doing most of my work from home. Luckily for me things like desks monitors and an office chair I always had since leaving university.  Other changes since my last blog post is that I have swapped a monthly rent to this mortgage thing which means I now have the ability to go mad with the home-lab.Working from home has resulted in having more devices from work. Due to a long and complicated reason I currently have 2 different laptops to do work along with all my other devices. For a long time I really wanted to upgrade my network for a number of different reasons but doing more work from home was the final straw.

Previously my network was very simple, there was the ISP Modem/Router/Wifi devices and I had an additional 18 port DLink unmanaged switch which I got free from an old employer.

With the new devices on the network I wanted to start using enterprise features such as VLAN's so that I could segregate my set of devices. I also wanted to have a better strength firewall solution that would restrict certain types of content as well as some network monitoring solution.

As the title to this post suggests I switched to using Ubiquiti network gear. Why Ubiquiti? Well its main selling point for me was their security camera product line.

Hang on you might be thinking this post is about networking not cameras?

Well I've been searching for a robust security camera system which was first self hosted, no monthly subscription, no sending you video on the cloud. I also wanted it to be as hassle free for example I don't want to be flashing firmware on cheap cameras.  After about 1 year searching for open-source camera monitoring solutions such as [motion-eye](https://github.com/ccrisan/motioneye) or **** BlueIris and cheap cameras that would work with the solution, I came across a from  Linus Tech ([https://www.youtube.com/watch?v=NkjD4xIhfTw](https://www.youtube.com/watch?v=NkjD4xIhfTw))

It looks that Ubiquiti has a whole range of security related products from indoor and outdoor camera,  They even have a RING door related product ([https://store.ui.com/collections/unifi-protect/products/uvc-g4-doorbell](https://store.ui.com/collections/unifi-protect/products/uvc-g4-doorbell)) Where all the data is stored locally and no monthly subscriptions, perfect.

Browsing Ubiquiti store and looking at videos it looks like their Dream Machine Pro  (UDM) was the perfect product I was looking for. The one single device could do everything I was looking for and more:

* Firewall
* Vlan management
* Advanced Threat Detection
* IP block whole regions of the world
* Security Camera recording

{{< figure src="/images/pBnqJvCCbfSp4Z6RxhupY2ni3CDcqErJhIl8Rjb1xI61uwBqglLrbf4XloycjvGe-BUTW_toJCdqlnsjFZIhO3NzXZ1P8T1_9dREaiuT0VA9fzYNcnrT0vrr3wiL5sxbuZGueUZp.jpg" >}}

Since I am replacing the ISP hub I will need a wifi access point as well. The UniFi  Access Point (AP) has many useful features  including  the ability to create multiple SSIDS from a single Access Point. Using these access points will also allow me to expand the network to gain more coverage if needed by just adding another AP in the future

The final device is the more tricky one, a modem. While the UDM has many features the one thing it does not have is a modem.  This was an adventure of its own. From reading old forums there seems to be two different manufacturers of Fibre to the cabinet (FTTC), ECI or Huawei.  There seems to be a debate if it matters if you use a ECI modem on a Huawei connection or vice vsa. So first who makes my FTTC cabinet, Sadly there is no simple way to look up that information. What there is a couple of great resources:

* [https://kitz.co.uk/adsl/fttc-cabinets.htm#fttc_street_cabinet](https://kitz.co.uk/adsl/fttc-cabinets.htm#fttc_street_cabinet) lists all the FTTC cabinet types
* [https://www.telecom-tariffs.co.uk/codelook.htm](https://www.telecom-tariffs.co.uk/codelook.htm) allows you based on your postcode or phone number workout what cabinet you are attached to and how far from the exchange you are.

Using the code lookup tool will tell you the cabinet number, so it was a just a quick 10 minute walk to have a look. But to be honest I could not tell the cabinet type as there were 4 cabinets in the single area and I was not taking out a tape measure.

I went with Huawei in part because they are easier to gain access to the management UI if needed and since most of the cabinets were newer there was a better change they were the Huawei type.

One week and £500 later I have in my house: a BT openreach modem, the UDM Pro and the UniFi  Access Point.  Setup could not have been easier, plugged everything in and after about 30 minutes for the UDM to complete its setup and connecting to the internet through the modem everything worked. Creating the networks I wanted also was a 5 minute process through the UI pretty much a point and click interface.

The diagram below shows the rough segmentation I currently have. There is a Corp network that contains the work laptops this network has its own work content policy. The IOT network contains the first gen Chrome-cast. I have an old Alexa and many phones, the final network is the dev network that contains my workstation as well as the home-lab servers.

{{< figure src="/images/yScq3hGZQ-2ICp5mP4LUHWDEpkBWtoXn6iRoRr5iwuixNOZYmR_97IjhnE2aIEvgyl7E1CHdhsso2v_Q0izqNjh2BzRwHwecBzT38ejAB-VgD_yXFD-J_cohu18vVFAt_a2XmLZy.jpg" >}}

It's been about 1 month since I have set this all up and I have not had a problem or any downtime with this setup so I am happy. Only thing I noticed is that I do now have way better wifi range from the new AP then I did from the ISP router even though they are in the same location. The final thing is that my current ISP has free hotspots if you allow the use of your own wifi, before disconnecting my old router I made sure that setting was still enabled so the ISP still allows me to use that feature when I am out and about.

The next post will be hopefully when I have all my cameras setup



