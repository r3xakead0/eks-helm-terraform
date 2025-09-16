variable "project_name" {
  type        = string
  default     = "eks-demo"
  description = "Nombre lógico del proyecto (prefijo)."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Región AWS."
}

variable "cluster_version" {
  type        = string
  default     = "1.29"
  description = "Versión de Kubernetes para EKS."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  default     = 3
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "map_users" {
  description = "Usuarios IAM adicionales para mapear en aws-auth."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
