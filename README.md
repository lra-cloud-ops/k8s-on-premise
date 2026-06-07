# Kubernetes On-Premise Cluster

<div align="center">

**LRA Cloud Operations**

![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31.14-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Calico](https://img.shields.io/badge/CNI-Calico_v3.27-FB8C00?style=for-the-badge&logo=linux&logoColor=white)
![containerd](https://img.shields.io/badge/Runtime-containerd_2.2.1-575757?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/OS-Ubuntu_22.04_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Vagrant](https://img.shields.io/badge/IaC-Vagrant-1563FF?style=for-the-badge&logo=vagrant&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-v3.21.0-0F1689?style=for-the-badge&logo=helm&logoColor=white)

*Clúster Kubernetes on-premise de 3 nodos, completamente automatizado con Vagrant y kubeadm*

</div>

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

## Arquitectura

```
┌──────────────────────────────────────────────────────────────┐
│                     Host (Windows)                           │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              CONTROL PLANE                          │   │
│   │              master-node · 192.168.56.10            │   │
│   │                                                     │   │
│   │   kube-apiserver · etcd · kube-scheduler            │   │
│   │   kube-controller-manager · calico-node             │   │
│   └──────────────────────┬──────────────────────────────┘   │
│                          │  192.168.56.0/24                  │
│              ┌───────────┴───────────┐                       │
│              │                       │                       │
│   ┌──────────▼──────────┐ ┌──────────▼──────────┐           │
│   │     WORKER NODE 1   │ │     WORKER NODE 2   │           │
│   │  worker-node1       │ │  worker-node2       │           │
│   │  192.168.56.11      │ │  192.168.56.12      │           │
│   │                     │ │                     │           │
│   │  kubelet            │ │  kubelet            │           │
│   │  kube-proxy         │ │  kube-proxy         │           │
│   │  containerd         │ │  containerd         │           │
│   │  calico-node        │ │  calico-node        │           │
│   └─────────────────────┘ └─────────────────────┘           │
└──────────────────────────────────────────────────────────────┘
```

---

## Stack Tecnológico

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

## Configuración de Red

| Nodo | IP | Rol |
|---|---|---|
| master-node | `192.168.56.10` | Control Plane |
| worker-node1 | `192.168.56.11` | Worker |
| worker-node2 | `192.168.56.12` | Worker |

| Red | CIDR |
|---|---|
| Red de nodos (Host-Only) | `192.168.56.0/24` |
| Red de Pods | `10.244.0.0/16` |
| Red de Servicios | `10.96.0.0/12` |

---

## Requisitos

- Windows 10/11 (64-bit)
- VirtualBox 7.2+
- Vagrant 2.x+
- Git
- **RAM:** 16 GB recomendado (8 GB mínimo)
- **CPU:** 8 núcleos recomendados (4 mínimo)
- **Disco:** 50 GB libres

---

## Despliegue Automatizado

El clúster se despliega completamente con un único comando. El proceso tarda ~15-20 minutos.

### 1. Clonar el repositorio

```bash
git clone https://github.com/lra-cloud-ops/k8s-on-premise.git
cd k8s-on-premise
```

### 2. Levantar el clúster

```bash
vagrant up
```

Vagrant ejecuta automáticamente en orden:

1. `common.sh` en los 3 nodos → instala containerd, kubeadm, kubelet, kubectl
2. `master.sh` en master → `kubeadm init` + Calico CNI + genera join token
3. `worker.sh` en workers → `kubeadm join` al clúster

### 3. Verificar el clúster

```bash
vagrant ssh master
kubectl get nodes -o wide
```

Output esperado:

```
NAME           STATUS   ROLES           AGE   VERSION    INTERNAL-IP
master-node    Ready    control-plane   -     v1.31.14   192.168.56.10
worker-node1   Ready    <none>          -     v1.31.14   192.168.56.11
worker-node2   Ready    <none>          -     v1.31.14   192.168.56.12
```

### 4. Instalar Helm y Metrics Server

```bash
bash scripts/helm-metrics.sh
```

Verificar métricas:

```bash
kubectl top nodes
kubectl top pods -n kube-system
```

---

## Estructura del Repositorio

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

## Operación

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

## Comandos Kubernetes útiles

```bash
# Estado del clúster
kubectl get nodes -o wide
kubectl get pods -n kube-system

# Métricas de recursos
kubectl top nodes
kubectl top pods -n kube-system

# Desplegar una aplicación de prueba
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc nginx

# Ver logs de un pod
kubectl logs -n kube-system <nombre-del-pod>

# Describir un nodo
kubectl describe node master-node

# Ver todos los recursos de un namespace
kubectl get all -n kube-system
```

---

## Resolución de Problemas

### Nodos en estado `NotReady`

**Causa:** El kubelet anuncia la IP del adaptador NAT (`10.0.2.15`) en vez de la red privada.

**Solución:**
```bash
echo 'KUBELET_EXTRA_ARGS=--node-ip=<IP_DEL_NODO>' | sudo tee /etc/default/kubelet
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

### Timeout en `vagrant up`

**Causa:** Las VMs tardan más del tiempo por defecto (300s) en arrancar.

**Solución:** Levantar los workers por separado:
```bash
vagrant up worker1
vagrant up worker2
```

### Error `conntrack not found` en kubeadm join

```bash
sudo apt-get install -y conntrack
```

### Error `containerd.sock not found`

```bash
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd && sudo systemctl enable containerd
```

---

## Componentes del Control Plane

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

<div align="center">

**LRA Cloud Operations**
[github.com/lra-cloud-ops](https://github.com/lra-cloud-ops) · Las Palmas de Gran Canaria, España - https://www.lracloudops.com/
</div>
