data "aws_caller_identity" "current" {}

resource "aws_security_group" "sg_web" {
  name        = "${var.project_name}-sg-web"
  description = "Web tier"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress_internet_to_web_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_web.id
}

resource "aws_security_group_rule" "ingress_internet_to_web_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_web.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = "${var.project_name}-cluster"
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true
  enable_irsa                    = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Otorga permisos de admin al creador (caller) del cluster
  enable_cluster_creator_admin_permissions = true

  # (Opcional) Define access entries para usuarios adicionales
  access_entries = {
    # Mapea la variable var.map_users (userarn/username) al rol/admin del clúster
    # Nota: las keys deben ser únicas; usamos el username como key.
    for u in var.map_users :
    u.username => {
      principal_arn = u.userarn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      desired_size   = var.desired_size
      min_size       = var.min_size
      max_size       = var.max_size
      instance_types = var.instance_types

      subnet_ids = module.vpc.private_subnets

      labels = {
        tier = "web"
      }
      taints = []

      create_security_group         = false
      additional_security_group_ids = [aws_security_group.sg_web.id]
    }
  }
}
