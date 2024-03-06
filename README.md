# Kubernetes Homelab

Welcome to the Kubernetes Homelab repository! Here, my friend and I plan to document our journey of self-hosting a couple of services using Kubernetes. We will be writing tutorials and blog posts about everything we do, and we aim to make it accessible to everyone, regardless of their existing knowledge of Kubernetes.

We strive to follow industry standards for a Kubernetes environment, but please note that this is not a recommended way to run a simple container in your home network. 

## Work in Progress

Please keep in mind that this repository is currently a work in progress. We will be adding colors (🍎🧡💚) next to sections to indicate their status (only 💚 sections are trustworthy). We also plan to add a static site generator at some point in the future.

To maintain stability, we aim to keep the `main` branch stable. Any work in progress or incomplete changes will be committed to the `unstable` branch. 

## Table of contents

⮬ If you're reading this on GitHub you can use the 🍔 menu on the top left.

## Setup 

### Tools / Software we will use 

- `ArgoCD`: ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.
- `Cert Manager`: Cert-manager is a native Kubernetes certificate management controller. It can help with issuing certificates from a variety of sources, such as Let’s Encrypt, HashiCorp Vault, Venafi, a simple signing key pair, or self-signed.
- `K3s`: Lightweight Kubernetes distribution, K3s is a lightweight Kubernetes distribution that is easy to install and requires minimal resources, making it ideal for running Kubernetes on edge devices or low-powered hardware.
- `k9s`: k9s is a terminal UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with observed Kubernetes resources.
- `kubectl`: The Kubernetes command-line tool, kubectl, allows you to run commands against Kubernetes clusters. You can use kubectl to deploy applications, inspect and manage cluster resources, and view logs.
- `Sealed Secrets`: Sealed Secrets is a Kubernetes controller and tool for one-way encrypted Secrets. It works by encrypting a Secret into a SealedSecret, which is safe to store - even to a public repository. The SealedSecret can be decrypted only by the controller running in the target cluster and nobody else (not even the original author) is able to obtain the original Secret from the SealedSecret.

## Setup on bare metal server running CentOS (or Fedora, or RHEL)
```bash
sudo dnf update                                       # update packages

sudo dnf copr enable varlad/helix                     # add helix editor repo
sudo dnf install helix                                # install helix editor

sudo dnf install cockpit                              # install a webinterface on 9090 
sudo systemctl enable --now cockpit
sed -i 's/root/#root/' /etc/cockpit/disallowed-users

sudo dnf install dnf-automatic                        # install a script which will update dnf for you
sed -i 's/apply_updates = no/apply_updates = yes/' \ 
/etc/dnf/automatic.conf                               # activate auto apply (not just downloads)
sudo systemctl enable --now dnf-automatic.timer       # start script

curl -sfL https://get.k3s.io | sh -i                  # install k3s

REMOTE="176.9.10.144"                                 # set remote host ip / fqdn
scp root@$REMOTE:/etc/rancher/k3s/k3s.yaml .          # copy k3s kubeconfig to local host
sudo chown $UID:$GID ./k3s.yaml                       # change kubeconfig ownership to your user
sed -i "s/127.0.0.1/$REMOTE/" ./k3s.yaml              # change the clusterapi ip / domain to your remote host
KUBECONFIG=./k3s.yaml kubectl get nodes               # test if everything is working (should return your node)

export KUBECONFIG=~/.kube/config:./k3s.yaml
kubectl config view --flatten > /tmp/config
cp ~/.kube/config ~/.kube/config.bak
cp /tmp/config ~/.kube/config
export KUBECONFIG=~/.kube/config
```

### Install k3s

#### If you're using NixOS:

```nix
service.k3s.enable = true; 
```

#### Every other Linux distribution:

https://docs.k3s.io/quick-start

### Install ArgoCD

https://argo-cd.readthedocs.io/en/stable/getting_started/

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Use Sealed Secrets to provide a Cloudflare DNS Token to your Cluster

Cert manager will use this token to automatically request TLS certificates from let's encrypt.

You don't have to use Cloudflare, but you will have to change the `issuer` in the `./tutorial/certmanger/cm-cert.yml` file.


If you choose to use Cloudflare, you can get your token at https://dash.cloudflare.com/profile/api-tokens.

Install sealed secrets:

```bash
kubectl apply -f ./argo/sealed_secrets.yaml
```

And install the local kubeseal cli.

Create the Cloudflare token secret:

```bash
kubectl create secret generic secret-name --dry-run=client --from-literal=api-token=[your-cloudflare-token] -o yaml | \
    kubeseal \
      --controller-name=sealed-secrets-controller \
      --controller-namespace=kubeseal \
      --format yaml > ./deployments/base/cloudflare-dns-api.yaml
```

This command will create a new encrypted secret and save it to `cloudflare-dns-api.yaml`. It will automatically deployed in the argocd step. 

### Configure Cert Manager

Change all email addresses and domains in `./deployments/base/cert-manager/` to your own.

### Use ArgoCD to bootstrap a basic cluster

Run `gitleaks detect` to check if you have any secrets in your repository:

Push your changes to a git repository and change the `repoURL` in `./argo/base.yaml` to your repository.

Open the ArgoCD web interface by port forwarding the service to your local machine (we will create a proper ingress later):

```bash
kubectl port-forward svc/argocd-server -n argocd 9090:443
```

Apply your Argo application:

```bash
kubectl apply -f argo # this will apply all files in the argo directory
```

Open the ArgoCD web interface at https://localhost:9090 and login using the default credentials:

username: admin
password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

You should now see your application in the ArgoCD web interface. Click on it and press `SYNC` to deploy your application.

### Adding a private repo to argo 

./argo/media.yaml is a private repo. To add it to argo you need to create a secret with your git credentials, or add them in the argocd webui. Otherwise argo wont be able to pull commits from the repo.
