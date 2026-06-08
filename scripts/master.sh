#!/bin/bash
# =============================================================================
# master.sh — Inicialización del Control Plane
# Ejecutar en: master-node únicamente
# =============================================================================
set -euo pipefail

MASTER_IP="192.168.56.10"
POD_CIDR="10.244.0.0/16"
NODE_NAME="master-node"
CALICO_VERSION="v3.27.0"
CALICO_MANIFEST="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml"
KUBECONFIG_PATH="/etc/kubernetes/admin.conf"
VAGRANT_USER="vagrant"

# -----------------------------------------------------------------------------
# IP del kubelet
# Por defecto kubelet anuncia la IP del adaptador NAT (10.0.2.15)
# Forzamos la IP de la red privada para que los nodos se comuniquen
# correctamente entre sí
# -----------------------------------------------------------------------------
echo "=== [1/4] Configurando IP del kubelet ==="
echo "KUBELET_EXTRA_ARGS=--node-ip=${MASTER_IP}" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

# -----------------------------------------------------------------------------
# kubeadm init
# Inicializa el Control Plane con la IP del master y el CIDR de Pods
# --apiserver-advertise-address: IP que anuncian los workers para unirse
# --pod-network-cidr: rango de IPs para los Pods — requerido por Calico
# -----------------------------------------------------------------------------
echo "=== [2/4] Inicializando Control Plane con kubeadm ==="
kubeadm init \
  --apiserver-advertise-address="${MASTER_IP}" \
  --pod-network-cidr="${POD_CIDR}" \
  --node-name="${NODE_NAME}"

# -----------------------------------------------------------------------------
# kubeconfig
# Copia las credenciales de admin al usuario vagrant para usar kubectl
# sin sudo desde la sesión SSH
# -----------------------------------------------------------------------------
echo "=== [3/4] Configurando kubectl para usuario ${VAGRANT_USER} ==="
mkdir -p /home/${VAGRANT_USER}/.kube
cp "${KUBECONFIG_PATH}" /home/${VAGRANT_USER}/.kube/config
chown -R ${VAGRANT_USER}:${VAGRANT_USER} /home/${VAGRANT_USER}/.kube

# -----------------------------------------------------------------------------
# Calico CNI
# Sin CNI los nodos quedan en NotReady — Calico implementa la red entre Pods
# y aplica NetworkPolicies para segmentación de tráfico
# -----------------------------------------------------------------------------
echo "=== [4/4] Instalando Calico CNI ${CALICO_VERSION} ==="
export KUBECONFIG="${KUBECONFIG_PATH}"
kubectl apply -f "${CALICO_MANIFEST}"

# -----------------------------------------------------------------------------
# join-command.sh
# Genera el token de unión para los workers y lo guarda en /vagrant
# que es la carpeta compartida entre el host y todas las VMs
# -----------------------------------------------------------------------------
echo "=== Generando join-command para workers ==="
kubeadm token create --print-join-command > /vagrant/join-command.sh
chmod +x /vagrant/join-command.sh

echo "=== [MASTER] Completado ==="
