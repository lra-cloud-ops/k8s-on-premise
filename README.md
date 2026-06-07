# k8s-on-premise

Clúster Kubernetes de 3 nodos desplegado on-premise con Vagrant, VirtualBox y kubeadm. Infraestructura completamente automatizada mediante scripts de provisioning. Proyecto en progreso con roadmap de 18 fases hacia una plataforma DevOps completa.

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31.14-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Helm](https://img.shields.io/badge/Helm-v3.21.0-0F1689?logo=helm&logoColor=white)](https://helm.sh)
[![Calico](https://img.shields.io/badge/Calico-v3.27-FB8C00)](https://projectcalico.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.x-1563FF?logo=vagrant&logoColor=white)](https://vagrantup.com)

---

## Roadmap

| Fase | Componente | Estado |
|---|---|---|
| Base | Vagrant · VirtualBox · Ubuntu · containerd · kubeadm · Calico | ✅ Completado |
| Fase 1 | Helm · Metrics Server | ✅ Completado |
| Fase 2 | Longhorn (almacenamiento persistente) | ⬜ Pendiente |
| Fase 3 | NGINX Ingress Controller | ⬜ Pendiente |
| Fase 4 | cert-manager (SSL/TLS) | ⬜ Pendiente |
| Fase 5 | PostgreSQL (StatefulSets) | ⬜ Pendiente |
| Fase 6 | Prometheus (métricas) | ⬜ Pendiente |
| Fase 7 | Grafana (dashboards) | ⬜ Pendiente |
| Fase 8 | Loki + Promtail (logging) | ⬜ Pendiente |
| Fase 9 | Alertmanager (alertas) | ⬜ Pendiente |
| Fase 10 | Harbor (registro de imágenes) | ⬜ Pendiente |
| Fase 11 | Jenkins (CI/CD) | ⬜ Pendiente |
| Fase 12 | SonarQube (calidad de código) | ⬜ Pendiente |
| Fase 13 | ArgoCD (GitOps) | ⬜ Pendiente |
| Fase 14 | HashiCorp Vault (secretos) | ⬜ Pendiente |
| Fase 15 | Trivy (seguridad) | ⬜ Pendiente |
| Fase 16 | Velero (backups) | ⬜ Pendiente |
| Fase 17 | App real — React + FastAPI + PostgreSQL | ⬜ Pendiente |
| Fase 18 | OpenTelemetry + Jaeger | ⬜ Pendiente |

---

## Architecture

```
Host (Windows)
├── master-node   192.168.56.10   Control Plane
│                                 kube-apiserver · etcd · kube-scheduler
│                                 kube-controller-manager · calico-node
├── worker-node1  192.168.56.11   Worker
│                                 kubelet · kube-proxy · containerd · calico-node
└── worker-node2  192.168.56.12   Worker
                                  kubelet · kube-proxy · containerd · calico-node

Red de nodos:    192.168.56.0/24
Red de Pods:     10.244.0.0/16
Red de Servicios: 10.96.0.0/12
```

---

## Stack

| Componente | Versión | Rol |
|---|---|---|
| Kubernetes | v1.31.14 | Orquestación de contenedores |
| kubeadm | v1.31.14 | Bootstrap del clúster |
| containerd | v2.2.1 | Container runtime (CRI) |
| Calico | v3.27.0 | CNI — Red de Pods |
| Helm | v3.21.0 | Package manager de Kubernetes |
| Metrics Server | v0.8.0 | Métricas de CPU y RAM |
| Ubuntu | 22.04 LTS | Sistema operativo base |
| Vagrant | 2.x | Provisioning de VMs |
| VirtualBox | 7.2 | Hypervisor |

---

## Requisitos

- Windows 10/11 (64-bit)
- VirtualBox 7.2+
- Vagrant 2.x+
- Git
- RAM: 16 GB recomendado (8 GB mínimo)
- CPU: 8 núcleos recomendados (4 mínimo)
- Disco: 50 GB libres

---

## Quickstart

```bash
git clone https://github.com/lra-cloud-ops/k8s-on-premise.git
cd k8s-on-premise
vagrant up
```

Vagrant ejecuta automáticamente en orden:

1. `common.sh` en los 3 nodos — instala containerd, kubeadm, kubelet, kubectl
2. `master.sh` en master — `kubeadm init` + Calico CNI + genera join token
3. `worker.sh` en workers — `kubeadm join` al clúster

Verificar el clúster:

```bash
vagrant ssh master
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

Output esperado:

```
NAME           STATUS   ROLES           AGE   VERSION    INTERNAL-IP
master-node    Ready    control-plane   -     v1.31.14   192.168.56.10
worker-node1   Ready    <none>          -     v1.31.14   192.168.56.11
worker-node2   Ready    <none>          -     v1.31.14   192.168.56.12
```

Instalar Helm y Metrics Server:

```bash
bash scripts/helm-metrics.sh
kubectl top nodes
kubectl top pods -n kube-system
```

---

## Project Structure

```
k8s-on-premise/
├── Vagrantfile              # Definición de infraestructura (IaC)
├── README.md                # Este documento
└── scripts/
    ├── common.sh            # Instalación base en los 3 nodos
    ├── master.sh            # Inicialización del Control Plane
    ├── worker.sh            # Join de los workers al clúster
    └── helm-metrics.sh      # Helm + Metrics Server (Fase 1)
```

---

## Operations

| Acción | Comando |
|---|---|
| Levantar clúster | `vagrant up` |
| Apagar clúster | `vagrant halt` |
| Reiniciar clúster | `vagrant reload` |
| Destruir clúster | `vagrant destroy --force` |
| SSH a master | `vagrant ssh master` |
| SSH a worker1 | `vagrant ssh worker1` |
| Estado de VMs | `vagrant status` |

---

## Control Plane Components

| Componente | Función |
|---|---|
| `kube-apiserver` | Punto de entrada de todas las operaciones. Expone la API REST de Kubernetes |
| `etcd` | Base de datos distribuida clave-valor. Almacena todo el estado del clúster |
| `kube-scheduler` | Asigna Pods a nodos basándose en recursos disponibles y restricciones |
| `kube-controller-manager` | Ejecuta los controladores que mantienen el estado deseado del clúster |
| `kubelet` | Agente en cada nodo. Gestiona los Pods y comunica con el API Server |
| `kube-proxy` | Gestiona las reglas de red (iptables/ipvs) para los Services |
| `containerd` | Runtime de contenedores compatible con CRI |
| `calico-node` | Implementa la red entre Pods y aplica NetworkPolicies |
| `metrics-server` | Recopila métricas de CPU y RAM. Habilita `kubectl top` y HPA |

---

## Troubleshooting

### Nodos en estado NotReady

Causa: el kubelet anuncia la IP del adaptador NAT (`10.0.2.15`) en vez de la red privada.

```bash
echo 'KUBELET_EXTRA_ARGS=--node-ip=<IP_DEL_NODO>' | sudo tee /etc/default/kubelet
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

### Timeout en vagrant up

Causa: las VMs tardan más del tiempo por defecto en arrancar.

```bash
vagrant up worker1
vagrant up worker2
```

### Error conntrack not found en kubeadm join

```bash
sudo apt-get install -y conntrack
```

### Error containerd.sock not found

```bash
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd && sudo systemctl enable containerd
```

---

Developed by [LRA Cloud Operations](https://www.lracloudops.com/) · [github.com/lra-cloud-ops](https://github.com/lra-cloud-ops) · Las Palmas de Gran Canaria, España
