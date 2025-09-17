# Identidad OIDC

## 1) Configurar el proveedor de identidad OIDC de GitHub en AWS

Esto permite que GitHub Actions se autentique en tu cuenta sin usar claves de acceso estáticas.

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com
```

(Si ya existe el OIDC provider, este comando fallará, pero no pasa nada.)

## 2) Crear una política de permisos para Terraform

Ejemplo: darle acceso a EKS, VPC, IAM, AutoScaling, S3, DynamoDB (ajusta según tus necesidades).

```bash
aws iam create-policy \
  --policy-name eks-demo-terraform-policy \
  --policy-document file://eks-demo-terraform-policy.json
```

## 3) Crear un Role con trust policy hacia GitHub

Crea un archivo trust-policy.json con el contenido siguiente (ajusta owner y repo):

```bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:<OWNER>/<REPO>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Crea el Role en AWS:

```bash
aws iam create-role \
  --role-name eks-demo-terraform-role \
  --assume-role-policy-document file://trust-policy.json
```

Asocia la política:

```bash
aws iam attach-role-policy \
  --role-name eks-demo-terraform-role \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/eks-demo-terraform-policy
```

## 4) Copiar el ARN del Role

Obtén el ARN del Role recién creado:

```bash
aws iam get-role --role-name eks-demo-terraform-role \
  --query 'Role.Arn' --output text
```

Ejemplo:

arn:aws:iam::123456789012:role/eks-demo-terraform-role

## 5) Crear el Secret en GitHub

1. Ve a tu repositorio en GitHub.

2. Settings → Security → Secrets and variables → Actions → New repository secret.

3. Nombre: AWS_ROLE_TO_ASSUME

4. Valor: pega el ARN del Role (ejemplo arn:aws:iam::123456789012:role/eks-demo-terraform-role).

5. Guardar.
