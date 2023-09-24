#!/usr/bin/env sh
set -xe 

export KUBECONFIG=~/.kube/config:"$1"
kubectl config view --flatten > /tmp/kubeconfig.yaml.tmp
cp ~/.kube/config ~/.kube/config.bak
cp /tmp/kubeconfig.yaml.tmp ~/.kube/config
