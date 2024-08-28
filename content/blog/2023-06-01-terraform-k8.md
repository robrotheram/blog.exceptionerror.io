+++
author = "Robert Fletcher"
date = 2023-06-01
description = "Building a new cluster"
draft = false
thumbnail = "/images/2023-05-21-Building-a-new-home-lab/thumbnail.png"
slug = "2023-06-01-terraform-k8-gitops"
tags = ["Homelab"]
title = "GitOPS with Terraform and ArgoCD"
images = ["/images/2023-05-21-Building-a-new-home-lab/thumbnail.png"]
+++

GitOps is getting a lot of buzz as the next evolution of DevOps, to put it in practice I am going to use it to manage my new Kubernetes cluster. I wanted to manage everything from application to DNS entries through an automated process, if I could I did not want to use any UI or type any command. 

### History time... 

If we turn back the clock 15 years before the terms like DevOPS were not in wide parlance, you will find in the IT departments these people called System Administrators. They would manage their servers as if they were you favourite pet. Most of the time they would be doing a lot of managing by hand, any maintenance would be manually typing the commands or running some custom script they had developed. Everything was very custom, and updates would require long outages and most people would dream about having separate development, reference and production environments. 

The first tool that popularized configuration as code was Puppet, which fit more into CaC (configuration as code) space. It did not provision any new servers but once installed it would enforce a set a set of configurations defined by its own DSL (domain specific language) that was stored in puppet server. Any updates to this DSL the puppet agent would apply it to the server and if a user logged in and changed some configuration the puppet agent would automatically revert it back.

Some of the problems with puppet were:

* It could not provision new hardware
* The DSL was complex and hard to learn compared to writing a bash script 
* It required a central server for the DSL to run and agents to connect to. 


In the mid 2010’s with everyone transitioning to the cloud came a bunch of agentless tools all under the banner of Infrastructure as Code. These tools such as Ansible or Terraform were built to stop Sysadmins from managing through the various cloud consoles, instead to define all the configuration upfront as to what they are going to deploy and what configuration to apply. This first allowed for faster disaster recovery, managing configurating drift and keeping infrastructure and configurations in their desired state and enabling version-controlled infrastructure and configuration by storing it in a version control system.

Now in 2020’s we build upon this with GitOps. 

### GitOps

GitOps is the next step by having a framework that takes DevOps best practices used for application development such as version control, collaboration, compliance, and CI/CD, and applies them to infrastructure automation.

GitOps has the following principles: 

1. **Declarative:** 
A system managed by GitOps must have its desired state expressed declaratively.


2. **Versioned and Immutable:**
Desired state is stored in a way that enforces immutability, versioning and retains a complete version history.


3. **Pulled Automatically:**
Software agents automatically pull the desired state declarations from the source.

4. **Continuously Reconciled:**
Software agents continuously observe actual system state and attempt to apply the desired state.

The main difference between IaC and GitOps is the level of automation that is used to manage the infrastructure. Instead of a developer deploying the infrastructure you let a Continuous Deployment (CD) tool do that for you. This means that you can manage each environment as branches in git and changes to production can be done with a Pull Request. 

## Cluster Provisiong

The service provider I using to host my single node cluster does not have a terraform provider, so the initial setup is still sadly manual. The only good part is that it literally only 2 commands to get a K3S cluster working and copying the Kubernetes configuration to be able to connect to it.
For anyone who has not heard about it https://k3s.io/ is a certified Lightweight Kubernetes distribution.  K3s is packaged as a single <70MB binary that reduces the dependencies and steps needed to install, run and auto-update a production Kubernetes cluster.

Now we have a K8 cluster setup with ingress controller. There are a few cluster Resources that we will deploy so that we can manage the applications using GitOps. 

```bash
curl -sfL https://get.k3s.io | sh - 
sudo cat /etc/rancher/k3s/k3s.yaml
```

Now we have a K8 cluster setup with ingress conroller. There are a few cluster Recources that we will deploy so that we can mange the applications using gitops. 

* **[Longhorn](https://longhorn.io/):** Cloud native distributed block storage for Kubernetes
* **[cert-manager](https://cert-manager.io/):** Issue certificates from a variety of supported sources, including Let's Encrypt, HashiCorp Vault, and Venafi as well as private PKI
* **[ExternalDNS](https://github.com/kubernetes-sigs/external-dns):** ExternalDNS synchronizes exposed Kubernetes Services and Ingresses with DNS providers.
* **[ArgoCD](https://argo-cd.readthedocs.io/en/stable/):** Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes 

For each of these services we could follow the getting started documentation for each service but then we would be straying from the GitOps process. Therefore, we will use terraform declare these resources. 

For each of these have a corresponding helm chart that we can deploy and customize the resulting terraform looks like this.

```HCL
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [ kubernetes_namespace.namespace ]
  name       = "cert-manager"
  namespace  = var.namespace
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    =  var.helm_version
  set {
    name  = "installCRDs"
    value = "true"
  }
}

```
With a simple terraform apply we now have everything we need to be able to deploy out k8 application from a git repository into our cluster. 

While we could deploy all the applications with terraform, we will use ArgoCD to manage the application state since its KNative and better suited for managing all Kubernetes resources . 

### ArgoCD

Argo CD follows the GitOps pattern of using Git repositories as the source of truth for defining the desired application state. Kubernetes manifests can be specified in several ways:

* kustomize applications
* helm charts
* jsonnet files
* Plain directory of YAML/json manifests

Argo CD automates the deployment of the desired application states in the specified target environments. Application deployments can track updates to branches, tags, or pinned to a specific version of manifests at a Git commit.

There are a few different ways you can have ArgoCD setup but for my deployment I want it to do the following:

1. Have ArgoCD look at a repository that stores the helm charts
2. Developer makes changes to the application configuration (new version of the application) and commit commits changes to a new branch 
3. Raises a PR
4. PR is approved 
5. Argo sees the changes to the main branch and deploys the changes into the cluster.


#### Deploying a new Application

For this example, I am going to deploy it-tools, it’s a simple webapp that has a bunch of useful tools for developers and people working in IT. Currently there is no official helm chart so I going to create my own. It just has a basic deployment and the ingress.

First, I going to ask the cluster to provision me a new TLS certificate for the domain use the Certificate CRD 

```YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: toolbox-tls
spec:
  dnsNames:
    - "toolbox.exceptionerror.io"
  secretName: toolbox-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```

For the Ingress I told it to use the above certificate for TLS and added the following annotation `external-dns.alpha.kubernetes.io/hostname`
This will tell my DNS provider (Cloudflare) that I want a new A record created for `toolbox.exceptionerror.io`


```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: w2g-ingress
  annotations:
    kubernetes.io/ingress.class: "traefik"    
    external-dns.alpha.kubernetes.io/hostname: toolbox.exceptionerror.io
spec:
  tls:
  - hosts:
    - toolbox.exceptionerror.io
    secretName: toolbox-tls
  rules:
  - host: toolbox.exceptionerror.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: toolbox
            port:
              number: 80
```

The helm chart is stored in a git repository. To deploy it we can either use Argo CD GUI or its CLI. 

```
argocd app create toolbox --repo https://github.com/username/my-infra-repo --path toolbox --dest-server https://kubernetes.default.svc --dest-namespace default
```

When deployed we can see in ArgoCD all the components that make up the application, from the pod to the certificate. 

![](/images/2023-05-21-Building-a-new-home-lab/toolbox.jpeg)


The problem is that we have just swapped one set of CLI / Web console to another. Can we store the initial Application creation in the git repository as well so that for a disaster recovery scenario all we would need to do is a single command and up comes all the applications. 

### Terraform ArgoCD

We already seen how we can use terraform to manage helm charts. With ArgoCD we either need its CLI or use the UI to deploy new applications, thanks to this custom provider by oboukili https://registry.terraform.io/providers/oboukili/argocd/latest we can use it to manage the Argo application. 

```HCL
resource "argocd_application" "toolbox" {
  depends_on = [ kubernetes_namespace.toolbox_namespace ]
  metadata {
    name      = "toolbox"
    namespace = var.namespace
  }

  spec {
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "toolbox"
    }

    source {
      repo_url        = "git@github.com:robrotheram/infrastructure.git"
      path            = "helmcharts/toolbox"
      target_revision = "HEAD"
      helm {
        value_files = ["values.yaml"]
      }
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
    }
  }
}
```

Now we can manage all the cluster resources application Certificates and even DNS entries from a single repository and deploy it all with a single terraform apply. 