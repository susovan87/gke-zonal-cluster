# Kubernetes Platform Components for GKE Zonal Cost-Optimized Environment

This directory contains Terraform configuration for deploying Kubernetes platform components on top of the GKE cluster created in the `2-gke` stage.

## Overview

This stage deploys the following platform components:

- **NGINX Ingress Controller**: Minimal ingress controller optimized for ARM nodes and spot instances
- **Cloudflare Tunnel**: Secure tunnel for external access (optional)
- **Storage Classes**: Cost-optimized and fast storage classes for different workload types

## Prerequisites

1. Complete deployment of `1-bootstrap` stage
2. Complete deployment of `2-gke` stage
3. Terraform ~> 1.12 installed
4. GKE cluster must be accessible and running
5. Configure `backend.config` with your GCS bucket details
6. Cloudflare account: If using Cloudflare Tunnel (optional)

## Components

### NGINX Ingress Controller
- Optimized for ARM64 architecture with dedicated ARM64 default backend
- Minimal resource configuration for cost savings
- ClusterIP service (external access handled by Cloudflare Tunnel)
- Custom security headers via ConfigMap
- Tolerations for spot nodes and ARM architecture

### Cloudflare Tunnel (Optional)
- **Remotely-managed tunnel** using token-based authentication (recommended by Cloudflare)
- Routes configured in Cloudflare Zero Trust Dashboard (not in Terraform)
- Secure tunnel for external access without exposing LoadBalancer services
- Metrics endpoint for monitoring and health checks
- Optimized for ARM64 spot instances with proper tolerations

### Storage Classes
- **cost-optimized**: Standard persistent disks (default)
- **fast**: SSD persistent disks for high-performance workloads

## Deployment

Configure backend and variables:
```bash
# Configure backend with your GCS bucket
cp backend.config.example backend.config
# Edit backend.config with your GCS bucket details

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project details
```

Deploy using Makefile:
```bash
make init
make plan
make apply
```

Check deployment status:
```bash
make status
```

## Configuration Variables

### Required Variables
- `tf_state_bucket`: GCS bucket name for Terraform state (from bootstrap stage)

### Optional Variables
- `platform_replicas`: Number of replicas for platform components (default: 2, must be 1 or 2)
- `enable_cloudflare_tunnel`: Enable Cloudflare Tunnel deployment (default: false)
- `cloudflare_tunnel_token`: Cloudflare Tunnel token for authentication
- `enable_storage_classes`: Enable custom storage classes (default: true)

### Dynamic Scaling
Platform components support dynamic scaling based on node count through the `platform_replicas` variable:
- **1 replica**: Cost-optimized mode (no PDBs, recreate strategy)
- **2 replicas**: High availability mode (with PDBs, rolling updates)

#### Scaling Process
**Important**: When scaling nodes, apply changes in the correct order to ensure proper Pod Disruption Budget configuration:

**Scaling Down (2 nodes → 1 node):**
1. First, apply `3-k8s-platform/` with `platform_replicas=1`
2. Then, apply `2-gke/` with `node_count=1`

**Scaling Up (1 node → 2 nodes):**
1. First, apply `2-gke/` with `node_count=2`  
2. Then, apply `3-k8s-platform/` with `platform_replicas=2`

This ensures PDBs and HA settings are configured appropriately to ease node drain operations.


## Troubleshooting

### Verification

After deployment, verify components:

```bash
# Check NGINX Ingress Controller
kubectl get pods -n ingress-nginx

# Check Cloudflare Tunnel (if enabled)
kubectl get pods -n cloudflare

# Check storage classes
kubectl get storageclass
```

## Cleanup

To remove all platform components:

```bash
make destroy
```

**Note**: This will not affect the underlying GKE cluster, which is managed in the `2-gke` stage.
