+++
author = "Robert Fletcher"
date = 2022-11-06T00:51:16Z
description = "Ok Microsoft take my money"
draft = false
thumbnail = "/images/2022-11-06-Microsoft-take-my-money/header.jpg"
slug = "2022-11-06-OK-Microsoft-take-my-money"
tags = ["Microsoft", "emails"]
title = "Part 1 Ok Microsoft take my money"
+++

God Dam it Microsoft fine just take my money!  

The story starts last month when one of my parents fell for one of the gift card scammers email. To be fair to my parents the hacker did not compromised there account, I have tried to get them to use good password quality.  What the scammers did was compromised their friend account and send the email. Being unsure, my parent sent a email confirming the gift-card to their friend second account, which was good thing. But the scammer being extra crafty they also compromised their friend second account so when my parent sent a email to the second account the scammer also responded pretending to be their friend.  Being busy at work my parent fell for it and bought and send the gift card.  Now down £100 and their pride I got some problems to solve. 

My parents are currently in their mid 60's about to enter retirements and while I would not class them as a digital native I think we could call them at least digital fluent. For the most all I do is a once a year PC / Phone checkup to make sure all is working well. 

I had a Grandparent that has a ipad and I would call having a basic grasp but as I watched over the years while they once could pick the occasional new think like switching form PC to IPad they are now at the point that new things e.g Whatsapp is now beyond them. 

Seeing all of this I need a solution to be able to manage my parents Online presents that can start off as a mostly hands off approach but with controls that I can use to have a more enfolded as they get older. The security landscape is also changing after the above incident they now have 2FA enabled on all accounts. But that comes with a new challenge they live 3 hours away so if a problem occurs I can not just come to their house to sort it out and now with 2FA I can't just log into their account from my house, well not without being on the phone which as all tech support people know is not a fun experience that I want to minimize.

The world is moving on and now most things are online only to mange things as phone support becomes less a normality and also the world is  multi device. When once it was just the family PC each person has at least one laptop and phone so that is 4 device just for my 2 parents alone. That does not include tablets smart watches and I currently think thank god there is no smart home stuff. But I wont be long until that may become a normality, urg.  

The final problem is more of a prediction I can see in the future. Looking at some of the new applications/services that are coming out in the last year or so e.g TailScale. They are not wanting to manage users/passwords (understandable) so are offloading the responsibility to third party identity services. You know the ones, the login with Google, Microsoft etc. While some do support other identity services they require Enterprise level accounts which for 4-5 people in total is no worth it. 

I do not want a 2nd Job as the Family Tech Support that now elevated as a Enterprise admin. 

I decided to work through ths problem as if I was at work and my parents are 2 clients that need a solution so what are the requirements.

- Must support multiple email accounts. Like any old business there always some historical thing you have to deal with, this case is that my parents have a joint email address that used for most stuff relating to bills that both people need access to.
- Need some way for remote management so if a hacker compromised the account we (which means me) can do some fast management and lock out the account
-  Support 2 factor authentication 
-  Mandated security controls
-  Future be able to do modern signing methods. (OIDC/SAML)


The problem is if I was looking at just managing email I could used something like FastMail. But for everything I basically have 3 options to choose from 

1. Use Microsoft 365
2. Use Google Workspaces
3. Set up my own Email on my own servers. 

I want to reduce the support burden as much as possible.

![](https://uploads-us-west-2.insided.com/freshworks-en/attachment/439baa98-06e0-4781-ba4c-6ad8ec84b2f7.jpg)
 As much as I love tinkering with servers its a bit like a person tinkering with a car. I would rather have a rented new car for the family to use that if there is a problem I just send it to the garage for them to fix under warranty, over the 3rd hand car that I am tinkering away at that half the time is broken. With that option 3 is off the table I am not running my own email server out of a tiny house.

Options 2 Google. I do still have a Google Workspace account which I have Grandfathered in on the old subscription so currently its free. But Google Workspace always feels like a 3rd class citizen of googles products, a pain to use and not feature complete.  I could go on a 5 minute rant but this clip from the WAN show helps make my point. https://www.youtube.com/watch?v=Uduia5slHdU 

![](https://killedbygoogle.com/social/card.png)

Coupled the unfinished nature of the service with the fact that Google's support is sketchy at best, what  on what it will kill next and I am not a fan of the new set of designs for GMail they urk me for some reason. 

So I am left with the final option Microsoft. What I want is basically the family plan with some extra controls that allow me to control the emails of each account, be able to reset users passwords remotely and access the inbox of the users. But sadly that not what Microsoft offers. 

Instead the final 4th secret option. Microsoft business account. This is probably the most expensive option but for about £5 a month per user its actually on par with something like fastMail. For their standard email price is $5 a user per month and that only gives you 30GB email while with Microsoft you get a 1TB of data. 

I can do all of the requirements listed above. It works with other apps that do signing with X, Also since its a business account it has a separate set of privacy arrangements. Sure compered with personal family plan its more expensive but it has a lot more features then just email and since its Microsoft the learning curve for my folks will be less of a issue, again I do not want a 2nd life as a tech supporter.  So I left with the fact OK Microsoft just take my money 

![](https://i.kym-cdn.com/photos/images/original/000/264/241/9e9.gif)













