#!/bin/bash
# =============================================================================
# platform.sh — Instalación completa del stack de la plataforma
# Ejecutar en: master-node únicamente, después de vagrant up
# Uso: bash /vagrant/scripts/platform.sh
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
HELM_VERSION="v3.21.0"
METRICS_SERVER_CHART="metrics-server/metrics-server"
INGRESS_NGINX_CHART="ingress-nginx/ingress-nginx"
ARGOCD_CHART="argo/argo-cd"
ARGOCD_REPO="https://github.com/lra-cloud-ops/k8s-on-premise"

# -----------------------------------------------------------------------------
# [1/6] Helm
# -----------------------------------------------------------------------------
echo "=== [1/6] Instalando Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -----------------------------------------------------------------------------
# [2/6] Repositorios Helm
# -----------------------------------------------------------------------------
echo "=== [2/6] Añadiendo repositorios Helm ==="
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# -----------------------------------------------------------------------------
# [3/6] Metrics Server
# InternalIP: evita timeout al scraping de kubelet en red privada
# -----------------------------------------------------------------------------
echo "=== [3/6] Instalando Metrics Server ==="
helm upgrade --install metrics-server ${METRICS_SERVER_CHART} \
  --namespace kube-system \
  --set 'args={--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}'

# -----------------------------------------------------------------------------
# [4/6] local-path-provisioner
# StorageClass ligero para lab — alternativa on-premise a EBS/PD
# -----------------------------------------------------------------------------
echo "=== [4/6] Instalando local-path-provisioner ==="
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# -----------------------------------------------------------------------------
# [5/6] NGINX Ingress Controller
# NodePort: no hay LoadBalancer en el lab
# 30080/30443: puertos fijos accesibles desde el host
# -----------------------------------------------------------------------------
echo "=== [5/6] Instalando NGINX Ingress Controller ==="
helm upgrade --install ingress-nginx ${INGRESS_NGINX_CHART} \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

# -----------------------------------------------------------------------------
# [6/6] ArgoCD
# GitOps engine — sincroniza el clúster con el repositorio GitHub
# -----------------------------------------------------------------------------
echo "=== [6/6] Instalando ArgoCD ==="
helm upgrade --install argocd ${ARGOCD_CHART} \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=ClusterIP \
  --timeout 10m

echo ""
echo "=== [PLATFORM] Esperando que los pods estén listos ==="
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=metrics-server \
  -n kube-system \
  --timeout=120s

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=ingress-nginx \
  -n ingress-nginx \
  --timeout=120s

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=180s

echo ""
echo "=== [PLATFORM] Completado ==="
echo ""
echo "Clúster:"
kubectl get nodes -o wide
echo ""
echo "StorageClass:"
kubectl get storageclass
echo ""
echo "Pods de la plataforma:"
kubectl get pods -n ingress-nginx
kubectl get pods -n argocd
echo ""
echo "ArgoCD password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
echo ""
echo "Acceso:"
echo "  ArgoCD UI: https://argocd.local:30443"
echo "  App demo:  http://nginx-lracloudops.local:30080"
