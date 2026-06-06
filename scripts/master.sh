#!/bin/bash
set -e

MASTER_IP="192.168.56.10"
POD_CIDR="10.244.0.0/16"

echo "=== [MASTER] Configurando IP del kubelet ==="
echo "KUBELET_EXTRA_ARGS=--node-ip=${MASTER_IP}" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

echo "=== [MASTER] Inicializando clúster con kubeadm ==="
kubeadm init \
  --apiserver-advertise-address=${MASTER_IP} \
  --pod-network-cidr=${POD_CIDR} \
  --node-name=master-node

echo "=== [MASTER] Configurando kubectl para usuario vagrant ==="
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

echo "=== [MASTER] Instalando Calico CNI ==="
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

echo "=== [MASTER] Generando comando join para workers ==="
kubeadm token create --print-join-command > /vagrant/join-command.sh
chmod +x /vagrant/join-command.sh

echo "=== [MASTER] Completado ==="
