#!/usr/bin/env sh
set -xe 

export KUBECONFIG=~/.kube/config:/etc/rancher/k3s/k3s.yaml:./k3s.yaml
kubectl config view --flatten > /tmp/kubeconfig.yaml.tmp
cp ~/.kube/config ~/.kube/config.bak
cp /tmp/kubeconfig.yaml.tmp ~/.kube/config
