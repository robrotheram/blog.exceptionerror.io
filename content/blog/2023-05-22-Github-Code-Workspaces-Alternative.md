+++
author = "Robert Fletcher"
title = "Github Code Workspaces Alternative "
date = "2023-05-22"
description = "Creating a one click development environment"
thumbnail= "/images/2023-05-22-Github-Code-Workspaces-Alternative/og-image.png"
slug = "2023-05-22-Creating-a-one-click-development-environment"
tags = [
    "Github",
    "Code Workspaces",
    "Coder",
    "DevEX",
]
images = ["/images/2023-05-22-Github-Code-Workspaces-Alternative/og-image.png"]
+++

As a Software developer when starting a new project, the first thing you must do is setup your workspace. Sometimes that is just git clone the repo to your laptop and you have all the tools installed. But I find most of the time you are presented with a blank server where you will do all your development in. Depending on how mature the project is and the makeup of the team you might just get a confluence page that contains 100 commands that you must run just to get a desktop and an IDE. If you are lucky someone will have automated the setup. But after writing these automation’s in almost every tool from bash, terraform and ansible they all require some form of upkeep, which is almost never the priority of the project especially if its short lived. On a good day this might take a new developer a day to get on-boarded onto a project and a lot of hand holding because those scripts will eventually break if not constantly maintained.   

![static](/images/2023-05-22-Github-Code-Workspaces-Alternative/codespaces-ga-individuals.webp)

Microsoft has solved this with GitHub Code Workspaces. 
They will spin up a ubuntu docker image with a vscode-server which you can then access it from any web browser. 
You can then customize the workspace with templates adding in your own specific tooling for example NODE, Java JDK or your own custom script. You can also define all the vs-code extensions you want loaded. This means that for every developer on the project can have identical working environments and it has required the team only a small amount of work to create it.
It’s amazing but one problem. Its proprietary to GitHub and all the code runs on Azure. The good news there was a good alternative GitPod.io has almost the same features as workspaces but does not have a tide to GitHub and could be self-hosted. But in November 2022 they released this statement.


>The last official update of this product is the November 2022 self-hosted release. We no longer sell commercial self-hosted licenses. If you want to self-host Gitpod, you can still request our free community license. However, we no longer offer support or updates for it. If you are interested in an isolated, private installation of Gitpod, take a look at Gitpod Dedicated. Read our blog on Gitpod Dedicated to learn why we made the decision to discontinue self-hosted.

So, we want is a GitHub workspace easy but can be self-hosted and if its open source even better.

# Coder

For the past few weeks on my own home-lab been trying a alternative coder.com. 
> Your Self-Hosted Remote Development Platform

It has a very interesting setup that I have not taken full advantage of yet.

The platform consists of workspaces that are built from templates. These templates can either be the inbuilt ones or you can customize yourself to fit the needs of the project. 

#### IDE's

With coder you are not limited to just vs-code. Coder will work with any IDE that supports ssh, so along with VS-CODE most of JetBrains IDEs' will work and even EMACS

You can also configure Web-based IDE from code-server, JetBrains Projector and for your Data Scientists JupyterLab. 

Imagine Data Scientists, a world where you are one click away from a notebook that already has all the dependency's you need and models setup. Not having to do a pip install again. 

## Templates 
From their documentation:

> With templates all you do is write normal Terraform that runs our startup script on provisioned compute. A development environment may consist of any Terraform resource, including virtual machines, containers, Kubernetes pods, or non-computing resources like secrets and databases.

Currently deployed the coder in my own kubernetes cluster so the templates I have written have been for deploying into a single pod into a environment.

But with these templates you can configure practically anything you can deploy with terraform from AWS RDS databases to full Kubernetes cluster in Azure. 

### Building my custom workspace

I wanted to try and build my own custom workspace based off the in build kubernetes version. Most of the projects I am currently working on are made up a similar set of tools: 
 - Go
 - React 
 - Docker
 - Hugo

I also wanted to track all the dependencies I use during development therefore I need the workspace to be configured to pull dependencies from nexus repository I have running.  Finally I want to try and make the onboarding setup easy for new projects similar to gitpod, So During workspace creation I want it to clone a existing project even if the repository was a private. 

To be able to use docker within the workspace I would base it off the work done by the coder team https://github.com/coder/envbox image 
and the https://github.com/coder/coder/tree/main/examples/templates/envbox template. 

The first part is relatively easy adding the required tools into the image This is done by just modifying the docker image.

``` Docker
FROM index.docker.io/codercom/enterprise-base:ubuntu
LABEL org.opencontainers.image.source="https://github.com/robrotheram/toolbox"
ENV GO_VERSION="1.20.4"
ENV GO_ARCH="amd64"
ENV HELM_VERSION="3.12.0"
ENV KUBE_VERSION="v1.27.1"
ENV NODE_VERSION="18.3.0"
ENV HUGO_VERSION="0.111.3"
ENV PATH="${PATH}:/usr/local/go/bin:/usr/local/nodejs/bin"

USER root
RUN apt-get update && apt-get install unzip zip jq -y && rm -rf /var/lib/apt/lists/*

RUN curl -O "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    && tar -xf "node-v${NODE_VERSION}-linux-x64.tar.xz" \
    && mv "node-v${NODE_VERSION}-linux-x64" /usr/local/nodejs \
    && rm "node-v${NODE_VERSION}-linux-x64.tar.xz"
RUN curl -O -L "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb" && dpkg -i hugo_extended_${HUGO_VERSION}_linux-amd64.deb && rm hugo_extended_${HUGO_VERSION}_linux-amd64.deb
RUN curl -O -L "https://golang.org/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" && tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" && rm "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
RUN curl -s "https://get.sdkman.io" | bash
RUN curl -LO "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl" && chmod +x ./kubectl && mv ./kubectl /usr/local/bin
RUN curl -O -L "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" && tar zxvf "helm-v${HELM_VERSION}-linux-amd64.tar.gz" && mv linux-amd64/helm  /usr/local/bin/helm && chmod +x /usr/local/bin/helm && rm -rf linux-amd64 && rm "helm-v${HELM_VERSION}-linux-amd64.tar.gz"

# Set back to coder user
USER coder

```

With the docker image created we need to update the template to allow a user to link their account to github and be able to clone a existing repo into the workspace. Thanks to some terraform snippets this is not that difficult. 

``` terraform
data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "https://github.com/robrotheram/toolbox"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

data "coder_parameter" "repo_url" {
  name        = "Repository"
  description = "Repository to clone"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

data "coder_parameter" "repo_dir" {
  name        = "Workspace"
  description = "Workspace to clone to"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "/emojis/1f4c1.png"
}

data "coder_git_auth" "github" {
  # Matches the ID of the git auth provider in Coder.
  id = "primary-github"
}

``` 

The final part for this setup is to modify the startup script to either clone the repo or if it already exists fetch 

``` terraform
resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"

  metadata {
    key          = "disk"
    display_name = "Home Volume Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large file systems
    script       = <<-EOT
      #!/bin/bash
      set -e
      df /home/coder | awk NR==2'{print $5}'
    EOT
  }

  login_before_ready = false  
  env                     = { 
    "DOTFILES_URI"  = data.coder_parameter.dotfiles_url.value != "" ? data.coder_parameter.dotfiles_url.value : null 
    "REPO_URL"      = data.coder_parameter.repo_url.value != "" ? data.coder_parameter.repo_url.value : null 
    "REPO_DIR"      = data.coder_parameter.repo_dir.value != "" ? data.coder_parameter.repo_dir.value : null 
  }      

  startup_script = <<EOT
    #!/bin/sh

    # home folder can be empty, so copying default bash settings
    if [ ! -f ~/.profile ]; then
      cp /etc/skel/.profile $HOME
    fi
    if [ ! -f ~/.bashrc ]; then
      cp /etc/skel/.bashrc $HOME
    fi

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s
    code-server --auth none --port 13337 > /dev/null 2>&1 &
    
    if [ -n "$DOTFILES_URI" ]; then
      echo "Installing dotfiles from $DOTFILES_URI"
      coder dotfiles -y "$DOTFILES_URI"
    fi

    if [ -n "$REPO_URL" ]; then
      if [ -d "$REPO_DIR" ]; then
        # Repository already exists, fetch updates
        cd "$REPO_DIR"
        git fetch
      else
        # Repository doesn't exist, clone it
        git clone "$REPO_URL" "$REPO_DIR"
      fi
    fi

  EOT
}
```

You can find all the full template example on my github https://github.com/robrotheram/toolbox


### Customizing after workspace creation    

Coder offers the coder dotfiles **repo** command which simplifies workspace personalization.  
You can read more on dotfiles https://coder.com/docs/v2/latest/dotfiles 

For me I just want to be able to setup golang and npm to use my nexus registry. Which now we are using dotfiles can be done with a couple of lines added to my bashrc profile.

--- 


### Workspaces

We can now use this custom template to create new workspaces for all the projects I am currently working on. All  I need to do  is click on a the template and launch a workspace. 

{{< video "/images/2023-05-22-Github-Code-Workspaces-Alternative/capture.mp4" >}}


<br/>

# Conclusion

Its been a couple of weeks I been using the workspaces and I have to admit its working well for me. Every so often I am away from my desktop, Visiting family and I am left with my 10 year old mac-book air that while good for web surfing is not up to development anymore but I can still ticker with one of my project thanks to coder.com



