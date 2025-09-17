#!/usr/bin/env bash
# scripts/bootstrap-backend.sh
# Crea/asegura el backend remoto de Terraform en S3 + DynamoDB (locks)

set -euo pipefail

: "${AWS_REGION:=us-east-1}"
: "${TF_STATE_BUCKET:=eks-demo-4565-tf-state-files}"
: "${TF_LOCKS_TABLE:=eks-demo-4565-tf-locks}"
: "${TF_STATE_KEY:=eks/dev/terraform.tfstate}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Falta '$1' en PATH"; exit 1; }; }
log()  { echo "[bootstrap] $*"; }

create_bucket() {
  local bucket="$1"
  local region="$2"

  if aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
    log "Bucket S3 ya existe: $bucket"
  else
    log "Creando bucket S3: $bucket (region: $region)"
    if [[ "$region" == "us-east-1" ]]; then
      aws s3api create-bucket --bucket "$bucket"
    else
      aws s3api create-bucket --bucket "$bucket" --region "$region" --create-bucket-configuration "LocationConstraint=$region"
    fi
  fi

  aws s3api put-public-access-block --bucket "$bucket" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "$bucket" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
}

create_locks_table() {
  local table="$1"
  if aws dynamodb describe-table --table-name "$table" >/dev/null 2>&1; then
    log "Tabla DynamoDB ya existe: $table"
  else
    log "Creando tabla DynamoDB: $table"
    aws dynamodb create-table --table-name "$table" --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
    aws dynamodb wait table-exists --table-name "$table"
  fi
}

show_block() {
  cat <<HCL

terraform {
  backend "s3" {
    bucket         = "${TF_STATE_BUCKET}"
    key            = "${TF_STATE_KEY}"
    region         = "${AWS_REGION}"
    dynamodb_table = "${TF_LOCKS_TABLE}"
    encrypt        = true
  }
}
HCL
}

need aws

log "Región: ${AWS_REGION}"
log "Bucket: ${TF_STATE_BUCKET}"
log "Tabla DynamoDB: ${TF_LOCKS_TABLE}"

create_bucket "$TF_STATE_BUCKET" "$AWS_REGION"
create_locks_table "$TF_LOCKS_TABLE"
show_block

log "Backend listo. Ejecuta 'terraform init -reconfigure' en ./terraform"
