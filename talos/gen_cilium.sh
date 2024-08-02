#!/usr/bin/env bash

helm template \
    cilium \
    cilium/cilium \
    --namespace kube-system \
    --set bpf.hostLegacyRouting=false \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set gatewayAPI.enabled=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set ipam.mode=kubernetes \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --version 1.16.0 > cilium.yaml

    # --set loadBalancer.dsrDispatch=geneve \
    # --set loadBalancer.mode=dsr \
    # --set routingMode=tunnel \
    # --set tunnelProtocol=geneve \
