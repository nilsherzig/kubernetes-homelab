#!/usr/bin/env bash 

set -e

# install argocd 
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# install sealed secrets and set cloudflare dns api token
kubectl apply -f ./apps/sealed_secrets.yaml
kubectl apply -f ./apps/base.yaml

read -rp "Enter your cloudflare dns token: " cloudflaretoken 
# kubectl create secret generic cloudflare-api-token-secret --dry-run=client --from-literal=api-token="$cloudflaretoken" -o yaml | \
#     kubeseal \
#       --controller-name=sealed-secrets-controller \
#       --controller-namespace=kubeseal \
#       --format yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  api-token: "$cloudflaretoken"
EOF

while true; do
  read -rp "Prod? (y/n) " choice
  
  case "$choice" in 
    y|Y ) 
      echo "Proceeding to setup a prod cluster..."
      kubectl apply -f ./apps/homelab-prod.yaml
      break
      ;;
    n|N )
      echo "Proceeding to setup a staging cluster..."
      kubectl apply -f ./apps/homelab-staging.yaml
      break  
      ;;
    * ) 
      echo "Invalid input. Please enter y or n."
      ;;
  esac
done
