#!/bin/bash
# Simple config restore from S3 using aws s3 sync

set -euo pipefail

S3_BUCKET="${1:-${S3_BUCKET:-project-configs-20250711124349990900000001}}"
echo "Using S3 bucket: $S3_BUCKET"

# Get the directory where this script is located, then go up one level to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
echo "Project root: $PROJECT_ROOT"

if [[ -z "$S3_BUCKET" ]]; then
    echo "Usage: $0 <s3-bucket-name>"
    echo "   or: S3_BUCKET=bucket-name $0"
    exit 1
fi

# Sync configs from S3 to local (only downloads changed files)
aws s3 sync "s3://$S3_BUCKET/gke-zonal-configs" "$PROJECT_ROOT" \
    --exclude "*"   \
    --include "*/terraform.tfvars" \
    --include "*/backend.config" \
    --include "*/application.properties"
