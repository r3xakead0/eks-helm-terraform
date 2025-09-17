resource "kubernetes_namespace" "tools" {
  metadata { name = "tools" }
}

resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"

  values = [
    jsonencode({
      rbac = { create = true },
      serviceAccount = {
        create = false,
        name   = kubernetes_service_account.cluster_autoscaler.metadata[0].name
      },
      autoDiscovery = {
        clusterName = module.eks.cluster_name
      },
      extraArgs = {
        "balance-similar-node-groups"   = "true",
        "skip-nodes-with-local-storage" = "false",
        "expander"                      = "least-waste"
      }
    })
  ]

  depends_on = [module.eks, aws_iam_role.cluster_autoscaler]
}
