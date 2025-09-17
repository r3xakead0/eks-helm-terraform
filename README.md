# eks-demo – Terraform EKS + Helm (us-east-1)

Plantilla lista para VS Code (con `.vscode/`) y GitHub Actions. Infra separada de la app web.

## Requisitos

- AWS CLI autenticado / o GitHub OIDC (ver workflows)
- Terraform >= 1.9
- kubectl, helm
- jq

## Backend remoto (estado de Terraform)

Primera vez, crear bucket y tabla DynamoDB (para locks):

```bash
# Crear bucket (cambia si el nombre ya existe globalmente)

aws s3api create-bucket \
 --bucket eks-demo-4565-tf-state-files \
 --region us-east-1 \
 --create-bucket-configuration LocationConstraint=us-east-1

# Habilitar versioning (opcional pero recomendado)

aws s3api put-bucket-versioning \
 --bucket eks-demo-4565-tf-state-files \
 --versioning-configuration Status=Enabled

# Crear tabla DynamoDB para locks

aws dynamodb create-table \
 --table-name eks-demo-4565-tf-locks \
 --attribute-definitions AttributeName=LockID,AttributeType=S \
 --key-schema AttributeName=LockID,KeyType=HASH \
 --billing-mode PAY_PER_REQUEST
```

**Alternativa:** ejecutar scripts/bootstrap-backend.sh que hace todo lo anterior automáticamente.

```bash
chmod +x scripts/bootstrap-backend.sh
./scripts/bootstrap-backend.sh
```

Después corre:

```bash
cd terraform
terraform init -reconfigure
```

## Uso local (rápido)

### Infraestructura

```bash
cd terraform
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

### Kubeconfig

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-demo-cluster
```

### Desplegar web por Helm

```bash
helm upgrade --install web-nginx ./web-chart --namespace default --create-namespace
```

### Validar

```bash
chmod +x scripts/validate-web.sh
NS=default RELEASE=web-nginx TIMEOUT=300 ./scripts/validate-web.sh
```

## VS Code

- Extensiones recomendadas y tareas en `.vscode/` (Terraform fmt/plan/apply, Helm, validate).
- Devcontainer opcional en `.devcontainer/`.

## Workflows (GitHub Actions)

- `.github/workflows/infra.yml` – Terraform (infraestructura).
- `.github/workflows/web.yml` – Helm (despliegue app web + validación).
