#!/bin/bash
# =============================================================================
# worker.sh — Join del worker al clúster
# Ejecutar en: worker1, worker2
# Argumento: $1 = IP privada del nodo
# =============================================================================
set -euo pipefail

NODE_IP="${1:?ERROR: NODE_IP no especificada. Uso: worker.sh <IP>}"

echo "=== [1/3] Limpiando estado previo de Kubernetes ==="
kubeadm reset --force 2>/dev/null || true
rm -rf /etc/kubernetes /var/lib/kubelet /etc/cni/net.d
iptables -F 2>/dev/null || true

echo "=== [2/3] Configurando IP del kubelet ==="
echo "KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

echo "=== [3/3] Uniéndose al clúster ==="
bash /vagrant/join-command.sh

echo "=== [WORKER] Completado ==="
