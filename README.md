# eks-demo – Terraform EKS + Helm (us-east-1)

Plantilla lista para VS Code (con `.vscode/`) y GitHub Actions. Infra separada de la app web.

## Requisitos
- AWS CLI autenticado / o GitHub OIDC (ver workflows)
- Terraform >= 1.9
- kubectl, helm
- jq

## Uso local (rápido)
```bash
# Infraestructura
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Kubeconfig
aws eks update-kubeconfig --region us-east-1 --name eks-demo-cluster

# Desplegar web por Helm
helm upgrade --install web-nginx ./web-chart --namespace default --create-namespace

# Validar
chmod +x scripts/validate-web.sh
NS=default RELEASE=web-nginx TIMEOUT=300 ./scripts/validate-web.sh
```

## VS Code
- Extensiones recomendadas y tareas en `.vscode/` (Terraform fmt/plan/apply, Helm, validate).
- Devcontainer opcional en `.devcontainer/`.

## Workflows
- `.github/workflows/infra.yml` – Terraform.
- `.github/workflows/web.yml` – Helm + validación.
