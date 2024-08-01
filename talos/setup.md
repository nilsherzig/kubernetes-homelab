# Initial install

1. Get the ISO using the factory generator
2. Create a new VM
    - enable SSD emulation, rest default
    - min 2 GB RAM
    - enable the qemu-guest-agent
3. Start VM
    - set `$CONTROL_PLANE_IP` to this VMs IP 


## Setup control plane nodes
```bash
export CONTROL_PLANE_IP="10.10.10.128"

# patches anwenden und config generieren
talosctl gen config k8s-dev https://$CONTROL_PLANE_IP:6443 --config-patch @patches.yaml --output-dir _out --install-image factory.talos.dev/installer/88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b:v1.7.5

# controll plane nodes erstellen
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file _out/controlplane.yaml
talosctl apply-config --insecure --nodes 10.10.10.219 --file _out/controlplane.yaml
talosctl apply-config --insecure --nodes 10.10.10.82 --file _out/controlplane.yaml
```

## bootstrap cluster

```bash
export CONTROL_PLANE_IP="10.10.10.128"
export TALOSCONFIG="_out/talosconfig"

talosctl config endpoint $CONTROL_PLANE_IP
talosctl config node $CONTROL_PLANE_IP


talosctl bootstrap
talosctl kubeconfig .
export KUBECONFIG=$(pwd)/kubeconfig
```

## install CNI

```bash
k apply -f ./cilium.yaml 
```

## add worker nodes

4. Create as many worker VMs as you need, note their IPs 
5. Run the following command for each worker VM (or supply more than one comma separated IP to --nodes)

```bash
talosctl apply-config --insecure --nodes 10.10.10.251 --file _out/worker.yaml
talosctl apply-config --insecure --nodes 10.10.10.36 --file _out/worker.yaml
talosctl apply-config --insecure --nodes 10.10.10.81 --file _out/worker.yaml
```

# Using the cluster

```bash
export KUBECONFIG=$(pwd)/kubeconfig
k get nodes
```

## installing Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## adding your Argo CD Apps

```bash
# deploy sealed secrets
k apply -f ../apps/sealed_secrets.yaml

# create cloudflare dns token (used by cert manager for acme)
CLOUDFLARE_TOKEN="[your token]"
kubectl create secret generic cloudflare-dns-token --dry-run=client --from-literal=api-token="$CLOUDFLARE_TOKEN" -n cert-manager -o yaml | kubeseal --controller-name=sealed-secrets-controller --controller-namespace=kubeseal --format yaml > ./deployments/base/cloudflare-dns-token.yaml

# deploy important base things (like cert manager)
k apply -f ../apps/base.yaml

# allow priv in longhorn-system namespace
k label ns longhorn-system pod-security.kubernetes.io/enforce=privileged
# deploy longhorn
k apply -f ../apps/longhorn.yaml

# deploy homepage
k apply -f ../apps/homelab-homepage.yaml

```

Argo CD allow auto created cilium items (otherwise Argo will remove them).

```bash
# open argocd configmap
kubectl edit cm argocd-cm -n argocd
```

```yaml
# add these items
data:
  resource.exclusions: |
    - apiGroups:
      - cilium.io
      kinds:
      - CiliumIdentity
      clusters:
      - "*"
```

## Enable resource consumption stats

## Add longhorn storage nodes 

- 3 x 4 TB storage nodes

## setup firewall rules using cilium  

### default ingress lock down mode

1. relevant files are at [base/cilium.yaml](../deployments/base/cilium.yaml)
2. debug using the following `hubble` command

```bash
hubble observe --identity ingress -f
kubectl -n kube-system exec -ti cilium-j48z7 -- cilium-dbg endpoint list
kubectl -n kube-system exec -ti cilium-j48z7 -- cilium-dbg endpoint get [endpoint id]
# you can use -o yaml if you get a json parsing error https://github.com/cilium/cilium/issues/29247
```
