# GKE Zonal Cost-Optimized Learning Environment

This project provides a cost-effective Google Kubernetes Engine (GKE) zonal cluster optimized for learning and experimentation, following best practices.

## 🏗️ Architecture Overview

The project is organized into three distinct Terraform stages:

```
terraform/
├── 1-bootstrap/      # Project and terraform backend setup
├── 2-gke/            # GKE cluster, networking, and node infrastructure
└── 3-k8s-platform/   # Platform components (NGINX Ingress, Argo CD, Cloudflare Tunnel, storage, namespace policies)
```

## 🎯 Key Features

- **Cost-Optimized**: ARM-based (t2a-standard-2) spot instances, minimal resources, zonal cluster
- **Homogeneous ARM64**: All nodes are ARM64. GKE auto-taints ARM64 nodes (`kubernetes.io/arch=arm64:NoSchedule`), so all workloads need a toleration. No `nodeSelector` needed for multi-arch images — use it only when an image lacks multi-platform support.
- **Security-First**: Workload Identity Federation, dedicated least-privilege node SA, private nodes, Dataplane V2 (Cilium/eBPF), Pod Security Standards, VPC-native networking, Cloud NAT for outbound access
- **Zero-Ingress Cost**: Cloudflare Tunnel integration (optional) eliminates Load Balancer costs
- **GitOps-Ready**: Optional Argo CD deployment for declarative application management
- **Learning-Focused**: Single-zone cluster with Makefile automation for easy management
- **Feature-Flagged**: All platform components are toggled via `enable_*` variables — deploy only what you need
- **Best Practices**: Multi-stage Terraform with remote state, separation of concerns

## 💰 Estimated Monthly Cost

With a single `t2a-standard-2` ARM spot node, expect approximately **~$23 USD/month**:

| Component | Est. Cost | Notes |
|-----------|-----------|-------|
| GKE zonal cluster management | $0 | [Always Free](https://cloud.google.com/free/docs/gcp-free-tier) tier (1 zonal cluster) |
| t2a-standard-2 Spot VM (2 vCPU / 8GB) | ~$13 | ARM spot pricing; varies by region |
| PSC forwarding rule | ~$6 | GKE 1.29+ uses PSC for control plane connectivity |
| Cloud NAT (gateway + external IP) | ~$4 | Required for private node outbound access |

### Why pay more for private nodes?

A public-node cluster avoids Cloud NAT and PSC costs, but each node still needs an external IPv4 address (~$3.65/month per node [since Feb 2024](https://cloud.google.com/vpc/network-pricing#ipaddress)). The real gap is ~$6/month — not free vs paid. This project chooses private nodes because:

- **No public IPs on nodes** — nodes are unreachable from the internet
- **Centralized egress via Cloud NAT** — one external IP serves all nodes, with auditable outbound traffic
- **Production-representative** — private networking with explicit egress is the standard for real workloads
- **Scales better** — public nodes pay ~$3.65/month *per node*; Cloud NAT's single IP covers any node count

Combined with Cloudflare Tunnel for ingress (avoiding $18+/month for a cloud Load Balancer), this gives a realistic private cluster setup at a modest premium over the bare-minimum public-node approach.

## 🚀 Quick Start

### Prerequisites
- Google Cloud Project with billing enabled
- Terraform ~> 1.14
- gcloud CLI configured
```bash
brew install --cask google-cloud-sdk # Install in MacOS
gcloud init # Initialize gcloud
gcloud auth list # Check active account
gcloud config list # Check active project
gcloud auth application-default login # Authenticate application default credentials
```
- kubectl (for cluster access)
- Helm (for platform components)

### Deployment Steps

Each stage has its own Makefile for simplified operations:

1. **Bootstrap** (creates GCS backend and enables APIs):
   ```bash
   cd terraform/1-bootstrap
   cp terraform.tfvars.example terraform.tfvars  # Edit with your project_id
   terraform init # Initialize Terraform with local state
   make apply
   make migrate-state  # Migrate to remote state after bootstrap
   ```

2. **GKE Cluster** (creates VPC, NAT, and cluster):
   ```bash
   cd terraform/2-gke
   cp terraform.tfvars.example terraform.tfvars     # Edit with bucket name from step 1
   cp backend.config.example backend.config         # Edit with bucket name
   make apply
   ```

3. **Platform Components** (installs NGINX Ingress, Argo CD, Cloudflare Tunnel, namespace policies):
   ```bash
   cd terraform/3-k8s-platform
   cp terraform.tfvars.example terraform.tfvars     # Configure feature flags as needed
   cp backend.config.example backend.config         # Edit with bucket name
   make apply
   ```

4. **Verify deployment**:
   ```bash
   gcloud container clusters get-credentials learning-cluster --zone us-central1-a
   kubectl get nodes
   ```

## ⚙️ Feature Flags

Most components are optional and controlled via `terraform.tfvars`:

| Variable | Stage | Default | Description |
|----------|-------|---------|-------------|
| `enable_vpa` | 2-gke | `false` | Vertical Pod Autoscaling addon |
| `enable_binary_authorization` | 2-gke | `false` | Binary Authorization (evaluation/dry-run mode) |
| `enable_argocd` | 3-k8s-platform | `false` | Argo CD deployment |
| `enable_argocd_ingress` | 3-k8s-platform | `false` | Ingress for Argo CD (default: use port-forward) |
| `argocd_hello_world_envs` | 3-k8s-platform | `{}` | Map of hello-world-app environments for Argo CD |
| `enable_cloudflare_tunnel` | 3-k8s-platform | `false` | Cloudflare Tunnel for zero-cost ingress |

## 🔒 Namespace Security Baseline

Every namespace in `var.namespaces` automatically receives a layered security baseline managed in `namespace-policies.tf`. Adding a new namespace to the map applies the full baseline — no manual policy creation needed.

### Pod Security Standards

Enforced via namespace labels (K8s 1.25+):

| Label | Level | Mode |
|-------|-------|------|
| `pod-security.kubernetes.io/enforce` | `baseline` | Reject violating pods |
| `pod-security.kubernetes.io/warn` | `restricted` | Warn on violations |
| `pod-security.kubernetes.io/audit` | `restricted` | Log violations |

PSS levels are configurable per namespace via `pss_enforce`, `pss_warn`, and `pss_audit` in the namespace object.

### Default LimitRanges

Every namespace gets a `default-limits` LimitRange that sets container resource defaults:

| Setting | Default |
|---------|---------|
| Default CPU / Memory | 500m / 256Mi |
| Request CPU / Memory | 50m / 64Mi |
| Max CPU / Memory | 1 / 512Mi |

All values are configurable per namespace via the `limit_range` object.

### Network Policies

Enforced via Dataplane V2 (Cilium/eBPF). Applied to all namespaces in `var.namespaces` plus component namespaces (`ingress-nginx`, `argocd`, `cloudflare`):

| Policy | Direction | Effect |
|--------|-----------|--------|
| `default-deny-ingress` | Ingress | Block all inbound traffic |
| `default-deny-egress` | Egress | Block all outbound traffic |
| `allow-dns-egress` | Egress | Allow DNS resolution to `kube-system` (port 53 UDP/TCP) |
| `allow-same-namespace` | Both | Allow intra-namespace pod communication |

#### Component-Specific Network Policies

Infrastructure components layer additional rules on top of the baseline:

| Component | Policy | Effect |
|-----------|--------|--------|
| NGINX Ingress | `allow-from-cloudflare-tunnel` | Cloudflare Tunnel → controller on ports 80/443 |
| NGINX Ingress | `allow-controller-egress` | Controller → any namespace (backend proxying + API server) |
| Argo CD | `allow-argocd-internal` | Internal communication (server, repo-server, controller, redis) |
| Argo CD | `allow-from-ingress-nginx` | NGINX Ingress → ArgoCD server on port 8080 |
| Argo CD | `allow-argocd-egress` | ArgoCD → external git repos, K8s API, app namespaces |
| Cloudflare Tunnel | `allow-metrics` | Metrics scraping on port 8080 |
| Cloudflare Tunnel | `allow-tunnel-egress` | Tunnel → Cloudflare edge + NGINX Ingress |
| hello-world-{stage,prod} | `allow-from-ingress-nginx` | NGINX Ingress → echo-app on port 8080 |

### Policy Organization

- **Baseline policies** (PSS, LimitRanges, Network Policies) are centralized in `namespace-policies.tf` using `for_each`
- **Component-specific network policies** live in their respective files (`nginx-ingress.tf`, `argocd.tf`, etc.)
- **Workload namespaces** only get the strict baseline — additional access must be explicitly declared per app
- **Infrastructure components** get unrestricted egress since they need API server, external services, and cross-namespace access

## 🔧 Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality.

### Setup

1. **Install pre-commit** (if not already installed):
   ```bash
   # Using pip
   pip install pre-commit

   # Using homebrew (macOS)
   brew install pre-commit
   ```

2. **Install the git hooks**:
   ```bash
   pre-commit install
   ```

### Manual Execution

Run hooks manually on all files:
```bash
# Run all pre-commit hooks
pre-commit run --all-files
```

## 🛠️ Management Commands

### Cluster Operations
```bash
# Get cluster credentials
gcloud container clusters get-credentials learning-cluster --zone us-central1-a

# Check cluster status
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Scale node pools (reduce platform_replicas in stage 3 first, then node_count in stage 2)
gcloud container clusters resize learning-cluster --node-pool spot-pool --num-nodes 2 --zone us-central1-a
```

### Platform Components
```bash
# Quick status check (from terraform/3-k8s-platform/)
make status

# Check NGINX Ingress
kubectl get pods -n ingress-nginx

# Check Argo CD (if enabled)
kubectl get pods -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d  # Get admin password
kubectl port-forward svc/argocd-server -n argocd 8080:443  # Access UI at https://localhost:8080

# Check Cloudflare Tunnel (if enabled)
kubectl get pods -n cloudflare

# Check storage classes
kubectl get storageclass
```

## 📦 Application Deployment

This project includes a [sample echo application](./k8s/hello-world-app/) using Kustomize with base/overlays pattern.

### Manual Deployment
```bash
kubectl apply -k k8s/hello-world-app/overlays/stage -n hello-world-stage   # Deploy to stage
kubectl apply -k k8s/hello-world-app/overlays/prod -n hello-world-prod     # Deploy to prod
```

### GitOps with Argo CD
When Argo CD is enabled (`enable_argocd = true`), configure `argocd_hello_world_envs` to have Argo CD manage the hello-world-app environments automatically.

## 📊 Monitoring

```bash
./scripts/monitor-cluster.sh  # Real-time cluster monitoring
```
