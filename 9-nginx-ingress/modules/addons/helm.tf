

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

resource "kubernetes_namespace" "ingress" {
  depends_on = [null_resource.kubeconfig,null_resource.tesd-config]

  metadata { name = "ingress-nginx" }

}

resource "kubernetes_namespace" "cert_manager" {
  depends_on = [null_resource.kubeconfig,null_resource.tesd-config]

  metadata { name = "cert-manager" }
}

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
        create = true
        name   = "external-dns"
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

    null_resource.kubeconfig,
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

resource "helm_release" "argocd" {
  depends_on = [null_resource.kubeconfig, helm_release.external-dns, helm_release.ingress, helm_release.cert-manager]

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  wait             = false

  set = [{
    name  = "global.domain"
    value = "learn-argocd-dev.mikeydevops1.online"
  }]

  values = [
    file("${path.module}/helmconfig/argocd.yml")
  ]
}

resource "helm_release" "external_secrets_operator" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.17" # or check latest below

  # optional: values.yaml-style customization
  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        create = true
      }
      webhook = {
        certManager = {
          enabled = false
        }
      }
    })
  ]
}

resource "helm_release" "psmdb_operator" {
  depends_on = [helm_release.external_secrets_operator]

  name       = "psmdb-operator"
  namespace  = "default"
  repository = "https://percona.github.io/percona-helm-charts/"
  chart      = "psmdb-operator"
  version    = "1.15.0" # keep pinned; upgrade intentionally

  # If you had a values.yaml in kustomize, put the same content here:
  # values = [
  #   file("${path.module}/values-operator.yaml")
  # ]

  # Safety: wait for resources/CRDs to settle before continuing
  wait          = true
  timeout       = 600
  recreate_pods = false
}