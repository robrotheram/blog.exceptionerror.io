+++
author = "Robert Fletcher"
date = 2022-02-09T00:51:16Z
description = ""
draft = false
image = "/images/2022-02-09-Moving-from-ghost-to-hugo/feature.png"
slug = "2022-02-09-Moving-from-ghost-to-hugo"
tags = ["Home", "lab", "Virtual machine's", "hugo"]
title = "Self hosting an auto-updating blog that is smaller then one photo"
+++

The title is not clickbait this entire site and webserver is being hosted in a container that is smaller then one of the photos I have taken. Ok slight cavitate my photos are taken in RAW and can average around 50mb per image. So maybe hosting an entire blog in 50mb. But before you guess no it not using volume mounts or anything like that all the images and post content is bundled in the container. 

So why did I do this? Well I am currently in the process of changing how I am managing services I am  running on my server and I wanted to get away from my old blogging platform ghost. While the editing and choice of themes are wonderful some of the new features and the market ghost is targeting is just not for me ahem. Newsletter, that you can not turn off. This tiny little blog does not need a news letter I don't thing anyone including myself need more email notifications. Anyway rant over, Time to pick a new platform. 

One of the other things I wanted to remove in this cleanup was reducing the number of databases and other services I am running so I needed a system that has no database. Enter Static Site Generators. Write everything in markdown and render some static HTML pages that you just point some webserver and huzzah you site. While there are many generators to use I went with hugo in part since is well supported, written in my favorite language but more importantly while browsing around I came across this [blog post](https://dwmkerr.com/migrating-from-ghost-to-hugo/) by Dave Kerr

In that post they mentioned a tool https://github.com/jbarone/ghostToHugo that does most of the heavy lifting on converting the blog to hugo. While using the script I noticed some changes I wanted to make mainly due to the way ghost handles images in 4.x which now stores images as: 
```
__GHOST_URL__/content/images/2017/03/HomeLabDiagram.png
```
Which does not work well in hugo. So time to break out vscode and create a PR that does the following changes:
- Posts created with there publish date prefix allowing you to see the order of the posts 
- For feature images, post card images and raw markdown, it will download the image and save to static/images and rewrite the URL to use the local files instead.

So if you want to use these extra changes you can view them on my fork: https://github.com/robrotheram/ghostToHugo


Excellent now the blog is exported all that is really left to do was pick a theme make some minor changes to suit my own needs and to make it look almost like my ghost blog and we are done. One static generating blog. 

---

## Building the Container that is smaller then one image




Now for the fun to begin creating a container that is less then one photo. Again on my travels around the net I found this post problem from hacker-news. https://lipanski.com/posts/smallest-docker-image-static-website
In there Florin Lipan explains how they went on a journey to create a single-layer image of 186KB webserver. 

So all that is left is that we create one crazy looking multistage dockerfile that uses hugo to generate the static site content build the tiny webserver and bundle it all into one image that is 50mb in size 

```docker
FROM node as hugo
RUN mkdir /app
WORKDIR /app
COPY . .
RUN wget -q https://github.com/gohugoio/hugo/releases/download/v0.92.1/hugo_0.92.1_Linux-64bit.tar.gz && tar zxvf hugo_0.92.1_Linux-64bit.tar.gz
RUN npm ci && npm i -g postcss-cli && ./hugo -D --gc
RUN ls -la
FROM alpine:3.13.2 AS builder

ARG THTTPD_VERSION=2.29

# Install all dependencies required for compiling thttpd
RUN apk add gcc musl-dev make

# Download thttpd sources
RUN wget http://www.acme.com/software/thttpd/thttpd-${THTTPD_VERSION}.tar.gz \
  && tar xzf thttpd-${THTTPD_VERSION}.tar.gz \
  && mv /thttpd-${THTTPD_VERSION} /thttpd

# Compile thttpd to a static binary which we can copy around
RUN cd /thttpd \
  && ./configure \
  && make CCOPT='-O2 -s -static' thttpd

# Create a non-root user to own the files and run our server
RUN adduser -D static

# Switch to the scratch image
FROM scratch
LABEL org.opencontainers.image.source="https://github.com/robrotheram/blog.exceptionerror.io"
EXPOSE 3000

# Copy over the user
COPY --from=builder /etc/passwd /etc/passwd

# Copy the thttpd static binary
COPY --from=builder /thttpd/thttpd /

# Use our non-root user
USER static
WORKDIR /home/static

# Copy the static website
# Use the .dockerignore file to control what ends up inside the image!
COPY --from=hugo /app/public /home/static

# Run thttpd
CMD ["/thttpd", "-D", "-h", "0.0.0.0", "-p", "3000", "-d", "/home/static", "-u", "static", "-l", "-", "-M", "60"]

```

---
## Automate all the things

One of the things you read around static site generators such as hugo is the ability to link it to something like Netlify so that you can commit your changes and see the result on the net. Grand but I self host and I want to do the same. Lets crack this puzzle. 

OK one cavitate here is that I going to use Github Actions in part as I do not currently have a CI setup at home but you could easily run the commands as part of a git hook or build it into your own pipeline. 

The pipeline below does only 3 basic things
- Builds the container using the dockerfile from above
- Push the container into a registry this time Github's own version. 
- Finally update a helm chart with the git hash. More on this later

```yml
name: Docker Image CI
on:
  push:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    name: build docker container
    steps:
    - uses: actions/checkout@v2
    - name: Login to GitHub Container Registry
      uses: docker/login-action@v1
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
        
    - name: Build the Docker image
      run: |
        docker build . --tag ghcr.io/robrotheram/blog:latest
        docker push ghcr.io/robrotheram/blog:latest
  deploy:
    needs: [build]
    runs-on: ubuntu-latest
    name: update the helm
    steps:
     - uses: actions/checkout@v2
     - name: Update values.yaml
       uses: fjogeleit/yaml-update-action@master
       with:
          valueFile: 'helm/values.yaml'
          propertyPath: 'image.commit'
          value: ${{ github.sha }}
          branch: 'main'
          commitChange: true
          updateFile: true
          message: "Update Helm"
```

Using this action now allows me anywhere in the world, well house or top of a large hill to make changes to the blog, commit and let github handle the building. 

While it would have been easier just to use github pages to host the site I like a good challenge and it does allow me to swap the CI part and the Container Registry part to different providers. 

### Deploying

At this point in time I have a my site in a container but I want to have this deployed and updated on every commit I make. Enter ArgoCD

{{<figure src="https://www.padok.fr/hubfs/Imported_Blog_Media/argo-1.webp" >}}

### What Is Argo CD?

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.
### How it works

Argo CD follows the GitOps pattern of using Git repositories as the source of truth for defining the desired application state. Kubernetes manifests can be specified in several ways:
    kustomize applications
    helm charts
    ksonnet applications
    jsonnet files
    Plain directory of YAML/json manifests
    Any custom config management tool configured as a config management plugin

Argo CD automates the deployment of the desired application states in the specified target environments. Application deployments can track updates to branches, tags, or pinned to a specific version of manifests at a Git commit. See tracking strategies for additional details about the different tracking strategies available.


### Deploying the blog. 

In the repo that contains the hugo static site and Docker file also lives a helm chart that tells Kubernetes how to deploy this site which also includes managing the SSL certificates. 

The final step in the Github action was to update a value in this helm chart that triggers argocd to do a redeployment. Argo will then download the new container image that contains the updated blog and redeploys it. Once I commit my updates to the blog it takes the lenght of time to go make a cup of tea for my changes to be available. Best of all its all open source (well once I replace github actions)


If all has gone to plan and you are reading this post then everything above will have justed worked. To be honest its taken about 3 days to get this far and it is definitely interesting journey not sure if anyone else would be mad enough to try it. 

{{<figure src="/images/2022-02-09-Moving-from-ghost-to-hugo/argocd.png" >}}