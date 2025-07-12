# Makefile for Kubernetes Platform Components
.PHONY: help init plan apply destroy clean status

# Default target
help:
	@echo "Available targets:"
	@echo "  init     - Initialize Terraform"
	@echo "  plan     - Plan Terraform changes"
	@echo "  apply    - Apply Terraform changes"
	@echo "  destroy  - Destroy Terraform resources"
	@echo "  clean    - Clean Terraform state and cache"
	@echo "  status   - Show deployment status"

# Initialize Terraform
init:
	@echo "Initializing Terraform for Kubernetes platform components..."
	terraform init -backend-config=backend.config

# Plan Terraform changes
plan:
	@echo "Planning Terraform changes..."
	terraform plan -var-file="terraform.tfvars"

# Apply Terraform changes
apply:
	@echo "Applying Terraform changes..."
	terraform apply -var-file="terraform.tfvars"

# Destroy Terraform resources
destroy:
	@echo "Destroying Kubernetes platform components..."
	terraform destroy -var-file="terraform.tfvars"

# Clean Terraform state and cache
clean:
	@echo "Cleaning Terraform state and cache..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*

# Show deployment status
status:
	@echo "Checking Kubernetes platform components status..."
	@echo "=== NGINX Ingress Controller ==="
	kubectl get pods -n ingress-nginx 2>/dev/null || echo "NGINX Ingress not deployed"
	@echo ""
	@echo "=== Cloudflare Tunnel ==="
	kubectl get pods -n cloudflare 2>/dev/null || echo "Cloudflare Tunnel not deployed"
	@echo ""
	@echo "=== Storage Classes ==="
	kubectl get storageclass 2>/dev/null || echo "Cannot access cluster"
