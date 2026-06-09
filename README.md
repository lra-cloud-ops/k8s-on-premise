# k8s-on-premise

Production-grade Kubernetes cluster deployed on-premise using kubeadm, Vagrant, and VirtualBox. Built following Red Hat engineering standards — automated, reproducible, and documented.

---

## Overview

This lab implements a multi-node Kubernetes cluster from scratch, following an 18-phase roadmap that covers the full DevOps stack: storage, ingress, observability, security, GitOps, and CI/CD. Each phase is production-oriented and interview-ready.

**Organization:** [LRA Cloud Operations](https://lracloudops.com)  
**Repository:** [github.com/lra-cloud-ops/k8s-on-premise](https://github.com/lra-cloud-ops/k8s-on-premise)

---

## Architecture

```
Host: Windows 11 Pro · Intel i7-13620H · 32GB RAM · 2.75TB

┌─────────────────────────────────────────────────────────┐
│                     VirtualBox                          │
│                                                         │
│  ┌──────────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │   master-node    │  │ worker-node1│  │worker-node2│  │
│  │ 192.168.56.10    │  │192.168.56.11│  │192.168.56.12│ │
│  │ 6GB RAM · 4 CPU  │  │6GB · 4 CPU  │  │6GB · 4 CPU│  │
│  │ Control Plane    │  │   Worker    │  │  Worker   │  │
│  └──────────────────┘  └─────────────┘  └───────────┘  │
│                                                         │
│  CNI: Calico v3.27.0    Runtime: containerd v2.2.1      │
│  Kubernetes: v1.31.14   OS: Ubuntu 22.04 LTS            │
└─────────────────────────────────────────────────────────┘
```

### Traffic Flow

```
Browser (host PC)
      │
      ▼
192.168.56.11:30080 (NodePort)
      │
      ▼
NGINX Ingress Controller
      │
      ├──► nginx-lracloudops.local  → nginx-lracloudops  (2-3 replicas)
      ├──► argocd.local:30443       → ArgoCD UI
      └──► grafana.local (planned)  → Grafana UI
```

---

## Quick Start

### Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| VirtualBox | 7.x | Hypervisor |
| Vagrant | 2.x | VM provisioning |
| Git | any | Source control |

**Minimum host resources:** 20GB RAM · 12 CPU cores · 150GB disk

### Deploy the cluster

```bash
git clone https://github.com/lra-cloud-ops/k8s-on-premise.git
cd k8s-on-premise
vagrant up
```

Provisioning takes approximately 20 minutes. The following runs automatically:

1. `common.sh` — installs containerd, kubeadm, kubelet, kubectl on all nodes
2. `master.sh` — initializes Control Plane, deploys Calico CNI
3. `worker.sh` — resets any prior state, joins workers to the cluster

### Post-install (run on master after vagrant up)

```bash
vagrant ssh master
bash /vagrant/scripts/post-install.sh
```

This installs Helm, Metrics Server, and local-path StorageClass.

### Verify

```bash
kubectl get nodes -o wide
kubectl top nodes
kubectl get storageclass
kubectl get pods -n ingress-nginx
kubectl get pods -n argocd
```

---

## Repository Structure

```
k8s-on-premise/
├── Vagrantfile                 # Infrastructure as Code — 3 VMs
├── README.md                   # This file
├── .gitignore                  # Excludes .vagrant/ and join-command.sh
├── apps/
│   └── nginx-lracloudops/      # GitOps demo app managed by ArgoCD
│       └── deployment.yaml     # Deployment + Service + Ingress
└── scripts/
    ├── common.sh               # Base setup — all nodes
    ├── master.sh               # Control Plane initialization
    ├── worker.sh               # Worker join (idempotent)
    ├── post-install.sh         # Helm + Metrics Server + StorageClass
    └── helm-metrics.sh         # Phase 1 reference script
```

---

## Roadmap

| Phase | Component | Status | Notes |
|---|---|---|---|
| Base | Vagrant · containerd · kubeadm · Calico | ✅ Complete | Fully automated |
| 1 | Helm v3.21.0 · Metrics Server v0.8.0 | ✅ Complete | kubectl top nodes working |
| 2 | local-path-provisioner (StorageClass) | ✅ Complete | Default StorageClass, PVC verified |
| 3 | NGINX Ingress Controller | ✅ Complete | NodePort 30080/30443, demo app exposed |
| 4 | cert-manager | ⬜ Planned | Automatic TLS certificates |
| 5 | PostgreSQL (StatefulSet) | ⬜ Planned | Persistent database |
| 6 | Prometheus | ⬜ Planned | Metrics collection |
| 7 | Grafana | ⬜ Planned | Metrics visualization |
| 8 | Loki + Promtail | ⬜ Planned | Log aggregation |
| 9 | Alertmanager | ⬜ Planned | Alert routing |
| 10 | Harbor | ⬜ Planned | Private container registry |
| 11 | Jenkins | ⬜ Planned | CI pipelines |
| 12 | SonarQube | ⬜ Planned | Code quality |
| 13 | ArgoCD v3.4.3 | ✅ Complete | GitOps demo — auto-sync from GitHub verified |
| 14 | HashiCorp Vault | ⬜ Planned | Secrets management |
| 15 | Trivy | ⬜ Planned | Container image scanning |
| 16 | Velero | ⬜ Planned | Backup and restore |
| 17 | Demo App | ⬜ Planned | React + FastAPI + PostgreSQL |
| 18 | OpenTelemetry + Jaeger | ⬜ Planned | Distributed tracing |

---

## GitOps with ArgoCD

ArgoCD watches this repository and automatically syncs any changes to the cluster. No manual `kubectl apply` in production.

### How it works

```
Git push → ArgoCD detects change (every 3 min) → kubectl apply → Pods updated
```

### Demo application

The `apps/nginx-lracloudops` directory is managed by ArgoCD. To demonstrate GitOps:

```bash
# Edit replicas in apps/nginx-lracloudops/deployment.yaml
# Change replicas: 2 to replicas: 3
git add . && git commit -m "feat: scale to 3 replicas" && git push
# ArgoCD applies the change automatically within 3 minutes
kubectl get pods -l app=nginx-lracloudops
```

### Access ArgoCD UI

Add to `C:\Windows\System32\drivers\etc\hosts`:
```
192.168.56.11 argocd.local
```

Open: `https://argocd.local:30443`  
Username: `admin`  
Password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

---

## Scripts

All scripts follow Red Hat engineering standards:

- `set -euo pipefail` — fail fast on any error
- Variables defined at the top — no magic strings
- Comments explain **why**, not what
- Numbered steps visible in provisioning output
- Idempotent — safe to run multiple times

### common.sh

Runs on all nodes. Installs and configures:

- Swap disabled (required by Kubernetes)
- Kernel modules: `overlay`, `br_netfilter`
- Network parameters: `ip_forward`, bridge iptables
- containerd with `SystemdCgroup = true`
- open-iscsi (storage prerequisite)
- kubeadm, kubelet, kubectl (pinned to v1.31, hold enabled)

### master.sh

Runs on master only:

- Configures kubelet node IP (prevents NAT IP announcement)
- `kubeadm init` with private network advertise address
- Copies kubeconfig for vagrant user
- Applies Calico CNI v3.27.0
- Generates `join-command.sh` in `/vagrant/` shared folder

### worker.sh

Runs on each worker with node IP as argument:

- `kubeadm reset --force` — cleans any prior Kubernetes state
- Removes `/etc/kubernetes`, `/var/lib/kubelet`, CNI config
- Flushes iptables
- Configures node IP for kubelet
- Executes join command from shared folder

### post-install.sh

Runs manually on master after `vagrant up`:

- Installs Helm v3 (latest)
- Installs Metrics Server with `--kubelet-preferred-address-types=InternalIP`
- Deploys local-path-provisioner
- Sets local-path as default StorageClass

---

## Known Issues and Solutions

| Issue | Root Cause | Solution |
|---|---|---|
| Nodes announce NAT IP (10.0.2.15) | kubelet default behavior | `KUBELET_EXTRA_ARGS=--node-ip` in `/etc/default/kubelet` |
| GPG fails in non-interactive mode | Missing batch flags | `gpg --batch --yes --dearmor` |
| kubeadm join fails on re-provision | Leftover Kubernetes files | `kubeadm reset --force` at start of `worker.sh` |
| VirtualBox orphaned VM directory | VMs not cleaned up properly | `Remove-Item -Recurse -Force "C:\Users\...\VirtualBox VMs\<name>"` |
| Metrics Server scrape timeout | Wrong address type | `--kubelet-preferred-address-types=InternalIP` |
| kubeconfig Forbidden after restart | Stale credentials | `sudo cp /etc/kubernetes/admin.conf ~/.kube/config` |
| vagrant up boot timeout | VMs slow to start with 6GB RAM | `config.vm.boot_timeout = 600` |

---

## Day-2 Operations

### Start the cluster

```bash
cd k8s-on-premise
vagrant up
vagrant ssh master
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
kubectl get nodes -o wide
```

### Stop the cluster (data preserved)

```bash
vagrant halt
```

### Destroy and rebuild from scratch

```bash
vagrant destroy --force
vagrant up
vagrant ssh master
bash /vagrant/scripts/post-install.sh
```

### Fix VirtualBox orphaned directory (Windows)

```powershell
Remove-Item -Recurse -Force "C:\Users\lique\VirtualBox VMs\<node-name>"
vagrant up <node>
```

---

## Git Workflow

This project uses semantic commits:

| Prefix | Purpose | Example |
|---|---|---|
| `feat:` | New functionality | `feat: add NGINX Ingress Controller` |
| `fix:` | Bug fix | `fix: add kubeadm reset before join` |
| `refactor:` | Code improvement | `refactor: rewrite scripts following Red Hat best practices` |
| `docs:` | Documentation | `docs: update README with Phase 3 and Phase 13 completion` |
| `chore:` | Maintenance | `chore: increase master RAM to 6GB` |

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| OS | Ubuntu LTS | 22.04 |
| Container runtime | containerd | 2.2.1 |
| Kubernetes | kubeadm / kubelet / kubectl | 1.31.14 |
| CNI | Calico | 3.27.0 |
| Package manager | Helm | 3.21.0 |
| Metrics | Metrics Server | 0.8.0 |
| Storage | local-path-provisioner | latest |
| Ingress | NGINX Ingress Controller | latest |
| GitOps | ArgoCD | 3.4.3 |
| Virtualization | VirtualBox + Vagrant | 7.x / 2.x |

---

## Author

**Ruben Alexis** · DevOps Engineer  
[LRA Cloud Operations](https://lracloudops.com) · [@lracloudops](https://instagram.com/lracloudops)
