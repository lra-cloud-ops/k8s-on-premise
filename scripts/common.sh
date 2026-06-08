#!/bin/bash
# =============================================================================
# common.sh — Configuración base para todos los nodos del clúster
# Ejecutar en: master, worker1, worker2
# =============================================================================
set -euo pipefail

KUBERNETES_VERSION="v1.31"
KUBERNETES_KEYRING="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
KUBERNETES_REPO="https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb"

# -----------------------------------------------------------------------------
# Swap
# Kubernetes requiere swap desactivado para gestionar memoria correctamente
# -----------------------------------------------------------------------------
echo "=== [1/5] Deshabilitando swap ==="
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# -----------------------------------------------------------------------------
# Módulos del kernel
# overlay: requerido por containerd para el sistema de archivos en capas
# br_netfilter: permite que iptables vea el tráfico de los bridges de red
# -----------------------------------------------------------------------------
echo "=== [2/5] Cargando módulos del kernel ==="
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# -----------------------------------------------------------------------------
# Parámetros de red
# ip_forward: permite el routing entre Pods de distintos nodos
# bridge-nf-call-iptables: permite que iptables filtre tráfico de bridges
# -----------------------------------------------------------------------------
echo "=== [3/5] Configurando parámetros de red ==="
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# -----------------------------------------------------------------------------
# containerd
# Runtime de contenedores compatible con CRI (Container Runtime Interface)
# SystemdCgroup=true: necesario para que kubelet y containerd usen el mismo
# gestor de cgroups y evitar conflictos de recursos
# -----------------------------------------------------------------------------
echo "=== [4/5] Instalando containerd ==="
apt-get update -y
apt-get install -y containerd conntrack

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# -----------------------------------------------------------------------------
# kubeadm · kubelet · kubectl
# kubeadm:  inicializa y une nodos al clúster
# kubelet:  agente que corre en cada nodo y gestiona los Pods
# kubectl:  CLI para interactuar con el clúster
# apt-mark hold: evita actualizaciones accidentales que rompan el clúster
# -----------------------------------------------------------------------------
echo "=== [5/5] Instalando kubeadm kubelet kubectl ==="
apt-get install -y apt-transport-https ca-certificates curl gpg

mkdir -p /etc/apt/keyrings
curl -fsSL "${KUBERNETES_REPO}/Release.key" \
  | gpg --batch --yes --dearmor -o "${KUBERNETES_KEYRING}"

echo "deb [signed-by=${KUBERNETES_KEYRING}] ${KUBERNETES_REPO}/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "=== [COMMON] Completado ==="
