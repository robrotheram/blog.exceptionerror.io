+++
author = "Robert Fletcher"
categories = ["Rclone", "Backups", "Nextcloud", "Backblaze"]
date = 2021-03-20T00:45:06Z
description = ""
draft = false
thumbnail = "/images/photo-157572985356.jpg"
slug = "my-backup-solution"
summary = "Backing up my data with Rclone, Nextcloud to Backblaze"
tags = ["Rclone", "Backups", "Nextcloud", "Backblaze"]
title = "Backups using Nextcloud, Rclone and Backblaze"

+++


Backups have always been a thing that I have half arsed and until now not got a complete solution that I was happy with. My previous solution was just to backup stuff onto a separate hard-drive in my PC every once in a while, no automation but  a backup copy is better than nothing. But with the news that OVH lost 2 data-centres ([https://www.theregister.com/2021/03/10/ovh_strasbourg_fire/](https://www.theregister.com/2021/03/10/ovh_strasbourg_fire/)) it was time to take the effort and get it sorted.

Over the years I tried many different solutions from [Borg backup](https://borgbackup.readthedocs.io/en/stable/), [Vorta](https://vorta.borgbase.com/) but nothing I was that confident on. My requirements for backups are as follows:

* Have a persistent notification that backups are working form the desktop toolbar. If the backups fail silently or require me to tail log files there is a good change I will not notice till it is too late.
* A good backup is only as good if you can restore it. Otherwise congrats on your terabyte blob of random data. This means that I would like to be able to see the files or use linux native tools (tar, unzip etc) to unpack archives. No custom format that only a single tool can read.
* Automated, once setup I want it to be able to be able to forget and not worry knowing that backups are happening
* Aim for the 3-2-1 backup strategy. This is the process of having 3 copies of the data on 2 different types of media and one to be offsite
* A copy has to remain in my house while one can live off site

After looking around at lots of tools but in the end instead of trying something new I went with what I already have set up in my house and just extended it to fit the needs of the above aims.

First (and most important) sync from my PC to some storage on my network I went with Nextcloud. I have had a Nextcloud server for around 4+ years but apart from some experiments and sharing some documents it has not been used. The new setup has Nextcloud hosted in docker with the storage mounted to a RAID 5 ZFS pool this should guarantee that integrity of the backup data. Another benefits of using Nextcloud is that I can get my phone to sync the high quality photos with no extra charge (urg thanks google)

Now with all the data in Nextcloud I have 2 copies of the data but if some disaster happens and I lose both the PC and the server it would be nice to have the data in some off-site location.

Again here there are many different solutions for off-site backups but the main concern is that I did not want to do deep analytics on my data and 200GB worth of photos (*looking at you Google, Microsoft). I also did not want to have another server to manage,  the best bet is to use a storage provider that charges you for data. The solution I went with Backblaze B2 storage it has a s3 compatible API and was way cheaper the S3

To backup from Nextcloud to Backblaze I use the well used tool Rclone that is a command line tool that supports many different providers including Backblaze.

The following diagram shows the data flow from all my servers more on the other servers later. You might notice a familiar naming scheme for my computers.

{{< figure src="/images/Untitled-Diagram-2-.png" >}}

To automate the Rclone backups I wrote based on some Reddit comments and a simple cron-tab script. The main part of the Rclone part of the script is the "**--use-json-log**" and **"--log-file"** This will write the Rclone logs to a file in a json format more on this later.

```
#!/bin/bash
mkdir -p /var/log/rclone
now=`date +%F`
if pidof -o %PPID -x “rclone-backup.sh”; then
exit 1
fi
rclone sync /storage-pool/nextcloud nextcloud-backup:excptionerror-io-nextcloud --use-json-log --log-level INFO  --log-file=/var/log/rclone/nexcloud-backup-$now.log
previous=`date --date='30 days ago' +%F`
rm -f /var/log/rclone/nexcloud-backup-$previous.log 2>&1
exit

```

While that completes the _"User"_ data portion of backups I run some other services from git servers to a custom gallery and the password manager Bitwarden. These are all running as containerised services with their data volume mounted to some directories. While these are running services they are only used by me and if the data died it would not be a great loss as I could reconstruct the data from other sources. With that being the case I decided to back this data up straight to Backblaze and just have a single remote copy.

Excellent I have now automated my backups to backblaze but how to monitor that rclone is working and get some stats around upload speed and progress uploaded. While I could SSH into the server tail the logs to see if this is working I wanted a visual way to see the progress.

Since I already had an ELK stack working and configured I added an additional config to filebeat to look at the RClone logs. By having the logs in the json format  it only took about  1 hour of building some simple visualizations in Kibana so that  I could have this simple dashboard that can monitor backups. In the future I will configure alerting to send me a email if the backups do not happen

{{< figure src="/images/image.png" >}}

It's not the most impressive dashboard but at a glance I can see if all the servers are backing up the data.

While this is not a complete solution and there are many small improvements I will fix in the future this is much better than what I once had. The final point is that with storing around 250GB of data it will cost around £20 a year which is not bad going.









