# Kubernetes Homelab

Welcome to the Kubernetes Homelab repository! Here, my friend and I plan to document our journey of self-hosting a couple of services using Kubernetes. We will be writing tutorials and blog posts about everything we do, and we aim to make it accessible to everyone, regardless of their existing knowledge of Kubernetes.

We strive to follow industry standards for a Kubernetes environment, but please note that this is not a recommended way to run a simple container in your home network. 

## Work in Progress

Please keep in mind that this repository is currently a work in progress. We will be adding colors (🍎🧡💚) next to sections to indicate their status (only 💚 sections are trustworthy). We also plan to add a static site generator at some point in the future.

To maintain stability, we aim to keep the `main` branch stable. Any work in progress or incomplete changes will be committed to the `unstable` branch. 

## Table of contents

⮬ If you're reading this on GitHub you can also use 🍔 menu on the top left.

## Setup 

### Overview 

- `K3s`: Lightweight Kubernetes distribution, K3s is a lightweight Kubernetes distribution that is easy to install and requires minimal resources, making it ideal for running Kubernetes on edge devices or low-powered hardware.
- `ArgoCD`: ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.
- `Sealed Secrets`: Sealed Secrets is a Kubernetes controller and tool for one-way encrypted Secrets. It works by encrypting a Secret into a SealedSecret, which is safe to store - even to a public repository. The SealedSecret can be decrypted only by the controller running in the target cluster and nobody else (not even the original author) is able to obtain the original Secret from the SealedSecret.

### Install k3s

#### If you're using NixOS:

```nix
service.k3s.enable = true; 
```

#### Every other Linux distribution:

https://docs.k3s.io/quick-start

### Install ArgoCD

https://argo-cd.readthedocs.io/en/stable/getting_started/

### Use Sealed Secrets to provide a Cloudflare DNS Token to your Cluster

Cert manager will use this token to automatically request TLS certificates from let's encrypt.

You don't have to use Cloudflare, but you will have to change the `issuer` in the `./tutorial/certmanger/cm-cert.yml` file.


If you choose to use Cloudflare, you can get your token at https://dash.cloudflare.com/profile/api-tokens.

Install sealed secrets:

```bash
helm install sealed-secrets -n kube-system --set-string fullnameOverride=sealed-secrets-controller sealed-secrets/sealed-secrets
```

Create the Cloudflare token secret:

```bash
kubectl create secret generic cloudflare-api-token-secret \
--dry-run=client \
--from-literal=api-token=[your-cloudflare-token] \
-n cert-manager \
-o yaml | kubeseal --format yaml > cloudflare-dns-api.yaml
```

This command will create a new encrypted secret and save it to `secret.yaml`. You can now apply this secret to your cluster.

### Configure Cert Manager

Change all email addresses and domains in `./deployments/base/cert-manager/` to your own.

### Use ArgoCD to bootstrap a basic cluster

Run gitleaks to check if you have any secrets in your repository:

Push your changes to a git repository and change the `repoURL` in `./argo/base.yaml` to your repository.

Open the ArgoCD web interface by port forwarding the service to your local machine (we will create a proper ingress later):

```bash
kubectl port-forward svc/argocd-server -n argocd 9090:443
```

Apply your Argo application:

```bash
kubectl apply -f argo/base.yaml
```

Open the ArgoCD web interface at https://localhost:9090 and login using the default credentials:

username: admin
password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

You should now see your application in the ArgoCD web interface. Click on it and press `SYNC` to deploy your application.
