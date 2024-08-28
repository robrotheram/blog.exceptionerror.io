+++
author = "Robert Fletcher"
date = 2022-11-06T00:51:16Z
description = "Ok Microsoft take my money"
draft = false
thumbnail = "/images/2022-11-06-Microsoft-take-my-money/header.jpg"
slug = "2022-11-06-OK-Microsoft-take-my-money"
tags = ["Microsoft", "emails"]
title = "Ok Microsoft take my money"
images = ["/images/2022-11-06-Microsoft-take-my-money/header.jpg"]
+++

God Dam it Microsoft, fine just take my money! 

The story starts last month when one of my parent's fell for one of the gift card scammers emails. To be fair to my parents the hacker did not compromise their account, I have tried to teach them good password quality. What the scammers did was compromised their friend's account and send the email. Being unsure about this out of the blue email, my parent sent an email confirming the gift-card to their friend second account, which was good thinking. But the scammer being extra crafty they also compromised their friend second account, so when my parent sent an email to the second account the scammer also responded pretending to be their friend. Being busy at work and getting an email confirming, they fell for it and bought and sent the gift card. 


<img src="https://media.makeameme.org/created/scammers-scammers-everywhere-5c6259.jpg" width="100%">


So, if you are reading this, first make sure you have a different password for every account and second enable 2 factor authentication if it is available. 

The £100 the scammer got is annoying but what worse is this now affects me. I have now a very concerned parent who is now metaphorically jumping when they hear a car back firing. 

My parents are currently in their mid 60's about to enter retirement and while I would not class them as a digitally native, I think we could call them at least digitally fluent. For the most part all I do is a once-a-year PC / Phone checkup to make sure all is working well. 

I do have a Grandparent that has an iPad and I would call having a basic grasp of technology. But as I watched over the years, while they once could pick the occasional new thing up, like switching from PC to iPad, they are now at the point that new things for example WhatsApp is now beyond them. 

Seeing all of this I need a solution to be able to manage my parent's online presence, that can start off as a mostly hands off approach but with controls that I can use to get more involved as they get older. The security landscape is also changing after the above incident, they now have 2FA enabled on all accounts. But that comes with a new challenge they live 3 hours away so if a problem occurs, I cannot just come to their house to sort it out and now with 2FA I can't just log into their account. 

The world is also moving on and now most interactions whether that is banking, managing council tax or just booking a hair dressing appointment are online only, as phone support becomes less a normality. Also, the world is multi device. When it was once just the family PC, now each person has at least a laptop, phone and possibly a tablet. Therefore, for just my parents one device is now six.  That does not include smart watches and thank God there is no smart home stuff, but it won't be long until that may become a normality 😩. 

The final problem is more of a prediction, I can see in the future where most services do not have username and passwords instead, they are delegating that responsibility to third party identity services. You know the ones, the login with Google, Microsoft etc. There are a few apps that have already done this and while some do support other identity services, they require Enterprise level accounts which for 4-5 people in total is not worth it.  

I decided to work through this problem as if I was at work and my parents are 2 clients that need a solution so what are the requirements.  

- Must support multiple email accounts. Like any old business there always some historical thing you have to deal with, this case is that my parents have a joint email address that used for most stuff relating to bills that both people need access to. 

- Need some way for remote management so if a hacker compromised the account, we (which means me) can do some fast management and lock out the account 

- Support 2 factor authentication 

- Mandated security controls 

- Future be able to do modern signing methods. (OIDC/SAML) 

The problem is if I was looking at just managing email, I could use something like FastMail. But for everything listed above I basically have 3 options to choose from 

1. Use Microsoft 365 

2. Use Google Workspaces 

3. Set up my own email on my own servers. 

 

I want to reduce the support burden as much as possible.  

![](https://aws1.discourse-cdn.com/business7/uploads/liquibase1/original/1X/e42fb8faacdc367ff0767e15c3dcc3557a9ad530.jpeg) 

 As much as I love tinkering with servers it's a bit like a person tinkering with a car. I would rather have a rented new car for the family to use that if there is a problem, I just send it to the garage for them to fix under warranty. Instead of the 3rd hand car that I am tinkering away at that half the time is broken. Since I want something with as much uptime as possible, option 3 is off the table. 

Option 2 Google.  While I still have an old GSuite account which I have grandfathered in on the old subscription so currently its free which is a plus. But Google Workspace always feels like a 3rd class citizen of googles products, a pain to use and not feature complete. I could go on a 5-minute rant but this clip from the WAN show helps make my point. 
<iframe width="100%" height="400" src="https://www.youtube.com/embed/Uduia5slHdU" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


Coupled the unfinished nature of the GSuite services with the fact that Google's support is sketchy at best and how long will it support it. Furthermore, I am not a fan of the new set of designs for Gmail. Sorry Google you were once so good now I am left with the final option Microsoft 😢.    

What I want is basically the family plan with some extra controls that allow me to control the emails of each account, be able to reset user's passwords remotely and access the inbox of the users. But sadly, that not what Microsoft offers. 

Instead, the final 4th secret option. Microsoft business account. This is probably the most expensive option but for about £5 a month per user its actually on par with something like FastMail. For their standard email price is $5 a user per month and that only gives you 30GB email while with Microsoft you get a 1TB of data. 

I can do all of the requirements listed above. It works with other apps that do signing with X, also since it's a business account it has a separate set of privacy arrangements. Sure, compared with personal family plan its more expensive but it has a lot more features then just email and since its Microsoft the learning curve for my folks will be less of an issue, again I do not want a 2nd life as a tech supporter. 
 
OK Microsoft just take my money.  

<img src="https://i.kym-cdn.com/photos/images/original/000/264/241/9e9.gif" width="100%"/>

I set up an account and 2 other users and have started playing around with all the options as a basic business account. Annoyingly currently all I got is positive things to say about the experience but I talk more in another post  







