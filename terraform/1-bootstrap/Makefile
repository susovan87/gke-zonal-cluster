# Makefile for GKE Zonal Cost-Optimized Learning Environment - Bootstrap

.PHONY: help init plan apply destroy clean migrate-state check-migration

# Default target
help:
	@echo "GKE Zonal Cost-Optimized Learning Environment - Bootstrap"
	@echo ""
	@echo "Commands:"
	@echo "  make init          - Initialize Terraform (local state)"
	@echo "  make plan          - Plan infrastructure changes"
	@echo "  make apply         - Deploy infrastructure"
	@echo "  make migrate-state - Migrate local state to remote GCS bucket"
	@echo "  make destroy       - Destroy infrastructure"
	@echo "  make clean         - Clean Terraform files"
	@echo ""
	@echo "Workflow: make apply → make migrate-state"

# Check if terraform.tfvars exists
check-config:
	@if [ ! -f terraform.tfvars ]; then \
		echo "Error: terraform.tfvars not found"; \
		echo "Copy terraform.tfvars.example to terraform.tfvars and configure it"; \
		exit 1; \
	fi

# Check if backend.config exists (for migration)
check-backend-config:
	@if [ ! -f backend.config ]; then \
		echo "backend.config not found. Copy from backend.config.example"; \
		exit 1; \
	fi

# Check if local state exists (indicates migration may be needed)
check-migration:
	@if [ -f terraform.tfstate ]; then \
		echo "Local state detected. Consider 'make migrate-state'"; \
	fi

init:
	terraform init -backend-config=backend.config

plan: check-config
	terraform plan -var-file="terraform.tfvars"

apply: check-config
	terraform apply -var-file="terraform.tfvars"
	@echo ""
	@echo "State bucket: $$(terraform output -raw terraform_state_bucket)"
	@echo "Run 'make migrate-state' to migrate to remote state"

migrate-state: check-config check-backend-config
	@echo "Migrating state to: $$(grep bucket backend.config | cut -d'=' -f2 | tr -d ' "')"
	@echo "Press Ctrl+C to cancel, or wait 3 seconds..."
	@sleep 3
	terraform init -migrate-state -backend-config=backend.config

destroy: check-config
	@echo "WARNING: This will destroy the GCS bucket and all stored state!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	terraform destroy -var-file="terraform.tfvars"

clean: check-migration
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
