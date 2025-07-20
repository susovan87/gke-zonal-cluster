# Simple Echo Service for GKE Testing

A minimal echo service to test your GKE cluster deployment using Kustomize for environment-specific configurations.


## Prerequisites

For end-to-end testing via ingress, ensure your GKE cluster has:
- ✅ NGINX Ingress Controller installed
- ✅ Cloudflare Tunnel configured for `*.mydomain.com`


## Quick Start

### Deploy to Development Environment

```bash
# Deploy using the default (development) configuration
kubectl apply -k .

# Or explicitly deploy to development
kubectl apply -k overlays/development
```

### Deploy to Production Environment

```bash
# Deploy to production
kubectl apply -k overlays/production
```

### Test the Service

```bash
# Check if pods are running
kubectl get pods -l app=echo-app

# Check if ingress is created
kubectl get ingress

# Test locally with port forwarding
kubectl port-forward svc/dev-echo-service-v1 8080:80

# In another terminal, test the echo service locally
curl http://localhost:8080

# Test via ingress (requires NGINX Ingress Controller and Cloudflare Tunnel)
# Development: curl https://echo-dev.mydomain.com
# Production:  curl https://echo.mydomain.com
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
# See what will be deployed to development
kubectl kustomize overlays/development

# See what will be deployed to production
kubectl kustomize overlays/production
```

### Scale the deployment
```bash
# Development
kubectl scale deployment dev-echo-app-v1 --replicas=2

# Production
kubectl scale deployment prod-echo-app-v1 --replicas=5
```

### View logs
```bash
# Development
kubectl logs -l app=echo-app,environment=development

# Production
kubectl logs -l app=echo-app,environment=production
```

### Check resource usage
```bash
kubectl top pods -l app=echo-app
```

### Verify ConfigMap generation
```bash
# Check generated ConfigMaps
kubectl get configmaps -l app=echo-app

# View ConfigMap contents
kubectl describe configmap dev-echo-config-v1-<hash>
```

## Clean Up

```bash
# Remove development deployment
kubectl delete -k overlays/development

# Remove production deployment
kubectl delete -k overlays/production

# Remove all deployments
kubectl delete -k .
```
