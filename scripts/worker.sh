#!/bin/bash
# =============================================================================
# worker.sh — Join del worker al clúster
# Ejecutar en: worker1, worker2
# Argumento: $1 = IP privada del nodo (192.168.56.11 o 192.168.56.12)
# =============================================================================
set -euo pipefail

NODE_IP="${1:?ERROR: NODE_IP no especificada. Uso: worker.sh <IP>}"

# -----------------------------------------------------------------------------
# IP del kubelet
# Mismo fix que en master — forzamos la IP de la red privada
# para que el nodo se registre con la IP correcta en el clúster
# -----------------------------------------------------------------------------
echo "=== [1/2] Configurando IP del kubelet ==="
echo "KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

# -----------------------------------------------------------------------------
# kubeadm join
# Usa el token generado por master.sh y guardado en /vagrant/join-command.sh
# /vagrant es la carpeta compartida entre el host y todas las VMs via VirtualBox
# -----------------------------------------------------------------------------
echo "=== [2/2] Uniéndose al clúster ==="
bash /vagrant/join-command.sh

echo "=== [WORKER] Completado ==="
