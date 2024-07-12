#!/usr/bin/env bash

helm template \
    cilium \
    cilium/cilium \
    --namespace kube-system \
    --set bandwidthManager.enabled=false \
    --set bpf.hostLegacyRouting=false \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set ingressController.default=true \
    --set ingressController.enabled=true \
    --set ingressController.hostNetwork.enabled=true \
    --set ingressController.hostNetwork.sharedListenerPort="8080" \
    --set ingressController.loadbalancerMode=shared  \
    --set ipam.mode=kubernetes \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --version 1.16.0-pre.3 > cilium.yaml

