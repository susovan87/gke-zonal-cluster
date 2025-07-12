# Bootstrap Terraform State Storage

Bootstrap configuration that must be run first to create:
- GCS bucket for Terraform state storage with versioning and lifecycle management
- Required Google Cloud APIs (Storage, Cloud Resource Manager)
- Random suffix for globally unique bucket naming

## Prerequisites

- GCP Project with billing enabled
- Terraform v1.12+ installed
- gcloud CLI authenticated with sufficient permissions

## Usage

1. Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your project details (use free tier eligible regions: us-central1, us-west1, us-east1):
```bash
vim terraform.tfvars
```

3. Initialize and apply (uses local state initially):
```bash
terraform init 
make apply
```

4. Note the output values, especially the `terraform_state_bucket` name, which you'll need for the infrastructure configuration.

## Important Notes

- **Initial Setup**: Uses local state since we're creating the remote state bucket
- **Security**: Bucket has uniform access control and restricted IAM permissions
- **Cost Optimization**: 7-day lifecycle rule for version cleanup
- **Protection**: Bucket is protected from accidental deletion with `prevent_destroy`

## State Migration

After successful deployment, migrate to remote state:
```bash
cp backend.config.example backend.config
vim backend.config   # Edit with your bucket name
make migrate-state
```

## Available Commands

You can see all available commands by running:
```bash
make
```

## Next Steps

After successfully applying this bootstrap configuration:
1. Use the output `terraform_state_bucket` name in the infrastructure configuration
2. Navigate to the `../2-gke` directory
3. Configure the backend to use the created GCS bucket
