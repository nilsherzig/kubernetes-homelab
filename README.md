# Kubernetes `Homelab`

## Table of contents

⮬ If you're reading this on GitHub you can also use 🍔 menu on the top left.

<!--toc:start-->
- [Kubernetes `Homelab`](#kubernetes-homelab)
  - [Table of contents](#table-of-contents)
  - [PLEASE READ](#please-read)
  - [Setup](#setup)
    - [install k3s](#install-k3s)
    - [Environment Variables](#environment-variables)
      - [Remote connection](#remote-connection)
  - [Ingress](#ingress)
    - [Example `whoami` pod](#example-whoami-pod)
    - [Connect to the pod](#connect-to-the-pod)
      - [Service](#service)
      - [Ingress path](#ingress-path)
    - [Adding TLS / SSL Certificates to our ingress](#adding-tls-ssl-certificates-to-our-ingress)
  - [`ArgoCD`](#argocd)
  - [`Kustomize`](#kustomize)
<!--toc:end-->

## PLEASE READ

This is very much work in progress, a friend and I plan to start self-hosting a couple of services. I will try to document the process in this repository and write tutorials / blog posts about everything we do. No existing knowledge Kubernetes will be required. 

I aim to follow most industry standards for a Kubernetes environment - or what I believe them to be. This is in no way a recommended way to run a simple container in your home network. 

Please keep in mind, that this is currently very much work in progress. I will add some colors (🍎🧡💚) next to sections (don't trust anything but 💚). I will add a static site generator at some point in the future.

## Setup 

### install k3s

Using NixOS: 

```nix
service.k3s.enable = true; 
```

### Environment Variables

You need to tell `kubectl` or other Kubernetes management tools, which cluster to use and where to find it. You can do this by setting your `KUBECONFIG` environment variable to the path of your clusters' config file.

```bash
export KUBECONFIG="/etc/rancher/k3s/k3s.yml"
```

Check if your connection is working by running 

```bash
kubectl get nodes
# NAME      STATUS   ROLES                  AGE   VERSION
# desktop   Ready    control-plane,master   20d   v1.27.5+k3s1
```

#### Remote connection

Or if you plan to connect to your cluster remotely, copy this config file to your external machine and modify the target IP / Port. Don't forget to change you `KUBECONFIG` variable. 

## Ingress 

You can find all relevant files inside the `./tutorial/ingress` Folder.

To keep everything clean and separated we will create a new namespace for this tutorial.

```bash
kubectl apply -f ./tutorial/ingress/whoami_ns.yml
```

To avoid having to add `-ns whoami` to every command, change your current namespace globally using 

```bash
kubens whoami # or just run kubens and use the fuzzy finder
```

### Example `whoami` pod

This pod will spawn a small web server with some information about incoming requests.

```bash
kubectl apply -f ./tutorial/ingress/whoami_pod.yml
# pod/whoami created
```

Check if your new pod was started by running:

```bash
kubectl get pods 
# NAME     READY   STATUS    RESTARTS   AGE
# whoami   1/1     Running   0          43s
```

### Connect to the pod

#### Service 

We want to connect to this `pod` without using something like port forwarding. We need to create a service object to accomplish this.

```bash
kubectl apply -f ./tutorial/ingress/whoami_service.yml
```

#### Ingress path

Now we need to expose this service on our host device. 

```bash
kubectl apply -f ./tutorial/ingress/whoami_ingress.yml
```

🎉 Your pod should now be reachable using your nodes IP / hostname and the right path.

```bash
curl -s http://[hostname]/testpath | head -n 3
# Hostname: whoami
# IP: 127.0.0.1
# IP: ::1
```

### Adding TLS / SSL Certificates to our ingress

We will use cert manager to automatically request TLS certificates from let's encrypt.

Install cert manager: 

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml  
```

add a new cluster issuer and DNS API Token:

> Somehow avoid pushing the secret onto GitHub haha (or even letting the API Token lie around on your system, could be bad enough) until then I'm just going to add `*secret.yml` to our `.gitignore` file.

Here is an example secret, create one of these and apply it (using a different token):  

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  api-token: 1111111111111111111-22222222222222222222
```

Please also change the Cloudflare & acme email address.

```bash
kubectl apply -f ./tutorial/certmanger/cm-cert.yml
```
