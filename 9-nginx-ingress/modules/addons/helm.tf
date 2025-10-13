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

# resource "helm_release" "external-dns" {
#   depends_on = [null_resource.kubeconfig,helm_release.ingress]
#   name       = "external-dns"
#   repository = "https://kubernetes-sigs.github.io/external-dns/"
#   chart      = "external-dns"
#   namespace  = "kube-system"
#
#   wait    = true
#   timeout = 600
#
# }
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
# resource "null_resource" "nginx_issuer" {
#   depends_on = [null_resource.kubeconfig, helm_release.cert-manager,null_resource.cert-manager-cluster-issuer,helm_release.external-dns,helm_release.ingress,null_resource.wait_ingress_ready]
#
#   provisioner "local-exec" {
#     command = "kubectl apply -f ${path.module}/helmconfig/nginx-ingress-setup.yml"
#   }
#
#
# }