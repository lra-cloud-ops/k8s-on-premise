#!/bin/bash
# =============================================================================
# post-install.sh — Instalación de herramientas después de vagrant up
# Ejecutar en: master-node únicamente
# =============================================================================
set -euo pipefail

echo "=== [1/4] Instalando Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== [2/4] Instalando Metrics Server ==="
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set 'args={--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}'

echo "=== [3/4] Instalando local-path-provisioner ==="
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

echo "=== [4/4] Configurando StorageClass por defecto ==="
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "=== [POST-INSTALL] Completado ==="
kubectl get nodes -o wide
kubectl get storageclass
