#!/bin/bash
# Fase 1 — Helm + Metrics Server

echo "=== Instalando Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== Añadiendo repositorio Metrics Server ==="
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

echo "=== Instalando Metrics Server ==="
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set 'args={--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}'
echo "=== Verificando ==="
sleep 30
kubectl top nodes
