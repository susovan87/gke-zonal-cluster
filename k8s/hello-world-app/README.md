# Simple Echo Service for GKE Testing

A minimal echo service to test your GKE cluster deployment using Kustomize for environment-specific configurations.


## Prerequisites

For end-to-end testing via ingress, ensure your GKE cluster has:
- ✅ NGINX Ingress Controller installed
- ✅ Cloudflare Tunnel configured for `*.mydomain.com`


## Quick Start

### Deploy to Stage Environment

```bash
# Deploy using the default (stage) configuration
kubectl apply -k . -n hello-world-stage

# Or explicitly deploy to stage
kubectl apply -k overlays/stage -n hello-world-stage
```

### Deploy to Prod Environment

```bash
# Deploy to prod
kubectl apply -k overlays/prod -n hello-world-prod
```

### Test the Service

```bash
# Check if pods are running
kubectl get pods -l app=echo-app -n hello-world-stage

# Check if ingress is created
kubectl get ingress -n hello-world-stage

# Test locally with port forwarding
kubectl port-forward svc/stg-echo-service-v1 8080:80 -n hello-world-stage

# In another terminal, test the echo service locally
curl http://localhost:8080

# Test via ingress (requires NGINX Ingress Controller and Cloudflare Tunnel)
# Stage: curl https://echo-stage.mydomain.com
# Prod:  curl https://echo.mydomain.com
```

## Configuration Management

### Environment Variables

The application uses ConfigMaps to manage environment-specific settings:

- `ECHO_APP_DOMAIN`: The domain for ingress routing
- `ECHO_TEXT`: The message returned by the echo service
- `ECHO_PORT`: The port the service listens on (default: 8080)


## Advanced Usage

### Preview Generated Manifests

```bash
# See what will be deployed to stage
kubectl kustomize overlays/stage

# See what will be deployed to prod
kubectl kustomize overlays/prod
```

### Scale the deployment
```bash
# Stage
kubectl scale deployment stg-echo-app-v1 --replicas=2 -n hello-world-stage

# Prod
kubectl scale deployment prod-echo-app-v1 --replicas=5 -n hello-world-prod
```

### View logs
```bash
# Stage
kubectl logs -l app=echo-app,environment=stage -n hello-world-stage

# Prod
kubectl logs -l app=echo-app,environment=prod -n hello-world-prod
```

### Check resource usage
```bash
kubectl top pods -l app=echo-app -n hello-world-stage
```

### Verify ConfigMap generation
```bash
# Check generated ConfigMaps
kubectl get configmaps -l app=echo-app -n hello-world-stage

# View ConfigMap contents
kubectl describe configmap stg-echo-config-v1-<hash> -n hello-world-stage
```

## Clean Up

```bash
# Remove stage deployment
kubectl delete -k overlays/stage -n hello-world-stage

# Remove prod deployment
kubectl delete -k overlays/prod -n hello-world-prod

# Remove all deployments
kubectl delete -k . -n hello-world-stage
```
