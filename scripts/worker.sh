#!/bin/bash
set -e

NODE_IP=$1  # Se pasa como argumento desde Vagrantfile

echo "=== [WORKER] Configurando IP del kubelet ==="
echo "KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

echo "=== [WORKER] Uniéndose al clúster ==="
bash /vagrant/join-command.sh

echo "=== [WORKER] Completado ==="
