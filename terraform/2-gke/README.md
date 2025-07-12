# GKE Zonal Cost-Optimized Infrastructure

This directory contains the core infrastructure configuration for the GKE zonal cluster, including:
- GKE cluster with optimized node pools
- Networking (VPC, subnets, Cloud NAT)
- Basic cluster configuration


## Prerequisites

1. **Bootstrap completed**: You must have run the bootstrap configuration in `../1-bootstrap/` first
2. **Bucket name**: Get the Terraform state bucket name from bootstrap output
3. (Optional) Install the GKE auth plugin for gcloud (needed for kubectl access):
```bash
gcloud components install gke-gcloud-auth-plugin
```

### Essential commands for managing the cluster

Initialize and apply the terraform configuration:
```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.config.example backend.config
# Edit terraform.tfvars with your project details and tf_state_bucket

make init
make plan
make apply
```

After applying, you can access the cluster using:
```bash
# To get credentials for the GKE cluster, run the output command
terraform output kubectl_config_command

kubectl get nodes -o wide
kubectl get pods --all-namespaces
kubectl get storageclass
kubectl cluster-info
gcloud container clusters resize learning-cluster --node-pool spot-pool --num-nodes <desired-count> --zone us-central1-a
kubectl get ingress --all-namespaces
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
kubectl port-forward -n ingress-nginx svc/nginx-ingress-ingress-nginx-controller 8080:80
```

## Architecture Overview

### Cluster Configuration
- **Type**: GKE Standard (zonal)
- **Location**: Single zone for cost optimization
- **Networking**: Private nodes with Cloud NAT
- **Release Channel**: REGULAR for stable updates
- **Features**: HPA enabled, HTTP Load Balancing disabled, DNS cache enabled

### Node Pools
- **Spot Pool**: ARM-based t2a-standard-2 instances (60-91% cost savings)
- **Regular Pool**: e2-medium for stateful workloads (not implemented to keep costs low)
- **Default**: 2 nodes, 30GB disk, auto-repair/upgrade enabled
- **Features**: Container-Optimized OS, secure boot enabled

### Networking
- **VPC**: Custom VPC with private subnets
- **Cloud NAT**: For outbound internet access
- **Firewall**: Internal communication, health checks, IAP SSH access
- **IP Ranges**: Subnet (10.0.0.0/24), Pods (10.1.0.0/16), Services (10.2.0.0/16)

## Cost Optimization

- **Spot instances**: Up to 91% cost savings
- **ARM-based nodes**: Additional cost savings
- **Zonal cluster**: No regional control plane costs
- **Minimal monitoring**: System components only
- **Disabled features**: HTTP Load Balancing, cluster autoscaling

## Monitoring and Maintenance

Use the provided scripts:
- `monitor-cluster.sh`: Overall cluster health


## Clean Up

To destroy the infrastructure:
```bash
make destroy
```

**Note**: This will delete all resources. Ensure you have backups of important data.
