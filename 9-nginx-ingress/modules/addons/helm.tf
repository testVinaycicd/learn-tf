resource "null_resource" "kubeconfig" {


  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} "
  }
}

resource "null_resource" "tesd-config" {
  depends_on = [null_resource.kubeconfig]

  provisioner "local-exec" {
    command = "kubectl get nodes "
  }
}

# resource "kubernetes_namespace" "ingress" {
#   depends_on = [null_resource.kubeconfig,null_resource.tesd-config]
#
#   metadata { name = "ingress-nginx" }
# }
#
# resource "kubernetes_namespace" "cert_manager" {
#   depends_on = [null_resource.kubeconfig,null_resource.tesd-config]
#
#   metadata { name = "cert-manager" }
# }

resource "helm_release" "ingress" {
  depends_on = [null_resource.kubeconfig,null_resource.tesd-config]
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  values = [
    file("${path.module }/helmconfig/ingress.yaml")
  ]

  wait    = true
  timeout = 600
}



resource "helm_release" "cert-manager" {
  depends_on       = [null_resource.kubeconfig,null_resource.tesd-config]
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"


  set  = [{
    name  = "installCRDs"
    value = "true"
  }]

  wait    = true
  timeout = 600

}



resource "null_resource" "cert-manager-cluster-issuer" {
  depends_on = [null_resource.kubeconfig, helm_release.cert-manager]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/helmconfig/cluster-issuer.yaml"
  }
}






data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  external_dns_sa_name      = "external-dns"
  external_dns_sa_namespace = "kube-system"
}

data "aws_iam_openid_connect_provider" "this" {
  arn = data.aws_eks_cluster.this.identity[0].oidc[0].issuer_arn
}

data "aws_iam_policy_document" "external_dns_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.external_dns_sa_namespace}:${local.external_dns_sa_name}"]
    }
  }
}



resource "aws_iam_policy" "external_dns" {
  name   = "${var.cluster_name}-ExternalDNS"
  policy = data.aws_iam_policy_document.external_dns_policy.json
}

data "aws_iam_policy_document" "external_dns_policy" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = local.external_dns_sa_name
    namespace = local.external_dns_sa_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
    labels = {
      "app.kubernetes.io/name" = "external-dns"
    }
  }
}


resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = local.external_dns_sa_name
      }
      provider     = "aws"
      policy       = "upsert-only"
      registry     = "txt"
      txtOwnerId   = "mikey"
      domainFilters = ["mikeydevops1.online"]
      sources      = ["ingress", "service"]
      aws = {
        zoneType = "public"
      }
      logLevel  = "info"
      interval  = "1m"
    })
  ]

  depends_on = [
    kubernetes_service_account.external_dns,
    aws_iam_role_policy_attachment.external_dns,null_resource.kubeconfig,
    helm_release.ingress
  ]


}




# resource "null_resource" "wait_ingress_ready" {
#   depends_on = [helm_release.ingress]
#
#   provisioner "local-exec" {
#     command = <<-EOT
#       set -euo pipefail
#
#       # 1) Controller up
#       kubectl -n ingress-nginx wait deploy/ingress-nginx-controller \
#         --for=condition=Available=True --timeout=5m
#
#       # 2) Admission jobs completed (names used by the official chart)
#       kubectl -n ingress-nginx wait job/ingress-nginx-admission-create \
#         --for=condition=complete --timeout=5m || true
#       kubectl -n ingress-nginx wait job/ingress-nginx-admission-patch \
#         --for=condition=complete --timeout=5m || true
#
#       # 3) Webhook object exists and has CABundle populated (best-effort check)
#       kubectl get validatingwebhookconfiguration ingress-nginx-admission >/dev/null 2>&1 || true
#     EOT
#   }
# }
#
resource "null_resource" "nginx_issuer" {
  depends_on = [null_resource.kubeconfig, helm_release.cert-manager,null_resource.cert-manager-cluster-issuer,helm_release.external-dns,helm_release.ingress]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/helmconfig/nginx-ingress-setup.yml"
  }


}