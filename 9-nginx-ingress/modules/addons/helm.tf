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
  depends_on = [null_resource.kubeconfig,null_resource.tesd-config,kubernetes_namespace.ingress]

  metadata { name = "ingress-nginx" }
}

resource "kubernetes_namespace" "cert_manager" {
  depends_on = [null_resource.kubeconfig,null_resource.tesd-config,kubernetes_namespace.ingress]

  metadata { name = "cert-manager" }
}

resource "helm_release" "ingress" {
  depends_on = [null_resource.kubeconfig,null_resource.tesd-config,kubernetes_namespace.ingress]
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress.metadata[0].name
  values = [
    file("${path.module }/helmconfig/ingress.yaml")
  ]

  wait    = true
  timeout = 600
}



resource "helm_release" "cert-manager" {
  depends_on       = [null_resource.kubeconfig,kubernetes_namespace.cert_manager,null_resource.tesd-config]
  name             = kubernetes_namespace.cert_manager.metadata[0].name
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = kubernetes_namespace.cert_manager.metadata[0].name


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
  depends_on = [null_resource.kubeconfig,helm_release.ingress]
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  wait    = true
  timeout = 600

}

resource "null_resource" "nginx_issuer" {
  depends_on = [null_resource.kubeconfig, helm_release.cert-manager,null_resource.cert-manager-cluster-issuer,helm_release.external-dns,helm_release.ingress]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/helmconfig/nginx-ingress-setup.yml"
  }


}