# Makefile for GKE Zonal Cost-Optimized Learning Environment

.PHONY: help init plan apply destroy clean

# Default target
help:
	@echo "GKE Zonal Cost-Optimized Learning Environment"
	@echo ""
	@echo "Commands:"
	@echo "  make init     - Initialize Terraform"
	@echo "  make plan     - Plan infrastructure changes"
	@echo "  make apply    - Deploy infrastructure"
	@echo "  make destroy  - Destroy infrastructure"
	@echo "  make clean    - Clean Terraform files"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - Copy terraform.tfvars.example to terraform.tfvars"
	@echo "  - Set your project_id in terraform.tfvars"
	@echo "  - Copy backend.config.example to backend.config"
	@echo "  - Set your tf_state_bucket in terraform.tfvars"

# Check if terraform.tfvars exists
check-config:
	@if [ ! -f terraform.tfvars ]; then \
		echo "Error: terraform.tfvars not found"; \
		echo "Copy terraform.tfvars.example to terraform.tfvars and configure it"; \
		exit 1; \
	fi

init:
	terraform init -backend-config=backend.config

plan: check-config
	terraform plan -var-file="terraform.tfvars"

apply: check-config
	terraform apply -var-file="terraform.tfvars"
	@echo ""
	@echo "🎉 Cluster deployed successfully!"
	@echo "Configure kubectl: $$(terraform output -raw kubectl_config_command)"

destroy: check-config
	@echo "⚠️  WARNING: This will destroy ALL infrastructure!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	terraform destroy -var-file="terraform.tfvars"

clean:
	rm -rf .terraform/
