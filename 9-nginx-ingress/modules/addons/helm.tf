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
  metadata { name = "ingress-nginx" }
}

resource "kubernetes_namespace" "cert_manager" {
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

resource "null_resource" "wait_ingress_ready" {
  depends_on = [helm_release.ingress]
  # provisioner "local-exec" {
  #   command = <<-EOT
  #     set -e
  #     kubectl -n ingress-nginx rollout status deploy/ingress-nginx-tf-1-controller --timeout=300s
  #     # Also ensure the admission service exists (webhook target)
  #     kubectl -n ingress-nginx get svc ingress-nginx-tf-1-controller-admission
  #   EOT
  # }
}

resource "helm_release" "cert-manager" {
  depends_on       = [null_resource.kubeconfig,null_resource.tesd-config]
  name             = kubernetes_namespace.cert_manager.metadata[0].name
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"


  set_sensitive = [ {
    name  = "installCRDs"
    value = "false"
  }]

  wait    = true
  timeout = 600

}

# 3b) Wait for cert-manager components
resource "null_resource" "wait_cert_manager" {
  depends_on = [helm_release.cert-manager]
  # provisioner "local-exec" {
  #   command = <<-EOT
  #     set -e
  #     kubectl -n cert-manager rollout status deploy/cert-manager           --timeout=300s
  #     kubectl -n cert-manager rollout status deploy/cert-manager-webhook   --timeout=300s
  #     kubectl -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=300s
  #   EOT
  # }
}

resource "null_resource" "cert-manager-cluster-issuer" {
  depends_on = [null_resource.kubeconfig, helm_release.cert-manager]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/helmconfig/cluster-issuer.yaml"
  }
}

resource "helm_release" "external-dns" {
  depends_on = [null_resource.kubeconfig]
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
}

resource "null_resource" "nginx_issuer" {
  depends_on = [null_resource.kubeconfig, helm_release.cert-manager,null_resource.cert-manager-cluster-issuer,helm_release.external-dns,null_resource.wait_ingress_ready]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/helmconfig/nginx-ingress-setup.yml"
  }
}