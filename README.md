# GKE Zonal Cost-Optimized Learning Environment

This project provides a cost-effective Google Kubernetes Engine (GKE) zonal cluster optimized for learning and experimentation, following best practices.

## 🏗️ Architecture Overview

The project is organized into three distinct Terraform stages:

```
terraform/
├── 1-bootstrap/      # Project and terraform backend setup
├── 2-gke/            # GKE cluster and infrastructure
└── 3-k8s-platform/   # Kubernetes platform components (ingress, storage, cloudflare tunnel etc.)
```

## 🎯 Key Features

- **Cost-Optimized**: ARM-based (t2a-standard-2) spot instances, minimal resources, zonal cluster
- **Security-First**: Private nodes, VPC-native networking, Cloud NAT for outbound access
- **Zero-Ingress Cost**: Cloudflare Tunnel integration (optional) eliminates Load Balancer costs
- **Learning-Focused**: Single-zone cluster with Makefile automation for easy management
- **Best Practices**: Multi-stage Terraform with remote state, separation of concerns

## 🚀 Quick Start

### Prerequisites
- Google Cloud Project with billing enabled
- Terraform ~> 1.12
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

3. **Platform Components** (installs NGINX Ingress, optional Cloudflare Tunnel):
   ```bash
   cd terraform/3-k8s-platform
   cp terraform.tfvars.example terraform.tfvars     # Configure as needed
   cp backend.config.example backend.config         # Edit with bucket name
   make apply
   ```

4. **Verify deployment**:
   ```bash
   gcloud container clusters get-credentials learning-cluster --zone us-central1-a
   kubectl get nodes
   ```

## 🔧 Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality. Note: `.pre-commit-config.yaml` needs to be added to the repository.

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
# Scale node pools
gcloud container clusters resize learning-cluster --node-pool spot-pool --num-nodes 2 --zone us-central1-a

# Get cluster credentials
gcloud container clusters get-credentials learning-cluster --zone us-central1-a

# Check cluster status
kubectl get nodes -o wide
kubectl get pods --all-namespaces
```

### Platform Components
```bash
# Check NGINX Ingress
kubectl get pods -n ingress-nginx

# Check Cloudflare Tunnel (if enabled)
kubectl get pods -n cloudflare

# Check storage classes
kubectl get storageclass
```

## 📦 Application Deployment
This project includes a [sample echo application](./k8s/hello-world-app/) to demonstrate deployment and management practices.

### Deploy to Development Environment

```bash
# Deploy to development
kubectl apply -k k8s/hello-world-app/overlays/development
```
```bash
# Deploy to production
kubectl apply -k k8s/hello-world-app/overlays/production
```