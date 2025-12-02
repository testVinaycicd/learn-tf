

resource "null_resource" "kubeconfig" {


  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} "
  }
}

resource "null_resource" "tesd-config" {
  depends_on = [null_resource.kubeconfig]

  provisioner "local-exec" {
    command = "kubectl create secret generic vault-token --from-literal=token=${var.vault_token} "
  }
}

resource "null_resource" "set-secret" {
  depends_on = [null_resource.kubeconfig]

  provisioner "local-exec" {
    command = "kubectl get nodes "
  }
}


resource "null_resource" "metrics-server" {
  depends_on = [null_resource.kubeconfig]

  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
  }
}

# resource "
#
#
# kubernetes_namespace" "ingress" {
#   depends_on = [null_resource.kubeconfig]
#
#   metadata { name = "ingress-nginx" }
#
# }
#
# resource "kubernetes_namespace" "cert_manager" {
#   depends_on = [null_resource.kubeconfig,null_resource.tesd-config]
#
#   metadata { name = "cert-manager" }
# }

# resource "helm_release" "ingress" {
#   depends_on = [null_resource.kubeconfig, helm_release.external-dns]
#   name             = "ingress-nginx"
#   repository       = "https://kubernetes.github.io/ingress-nginx"
#   chart            = "ingress-nginx"
#   namespace        = "ingress-nginx"
#   version          = "4.14.0"
#   create_namespace = true
#   values = [
#     file("${path.module }/helmconfig/ingress.yaml")
#   ]
#
#   atomic          = true
#   cleanup_on_fail = true
#   wait            = true
#   timeout         = 1800
# }



# resource "helm_release" "cert-manager" {
#   depends_on = [null_resource.kubeconfig, null_resource.tesd-config]
#   name             = "cert-manager"
#   repository       = "https://charts.jetstack.io"
#   chart            = "cert-manager"
#   namespace        = "cert-manager"
#   version          = "1.19.1"
#   create_namespace = true
#
#   set = [
#     {
#       name  = "installCRDs"
#       value = "true"
#     }
#   ]
#   atomic          = true
#   cleanup_on_fail = true
#   wait            = true
#   timeout         = 1800
#
# }
#
#
#
# resource "null_resource" "cert-manager-cluster-issuer" {
#   depends_on = [null_resource.kubeconfig, helm_release.cert-manager]
#
#   provisioner "local-exec" {
#     command = "kubectl apply -f ${path.module}/helmconfig/cluster-issuer.yaml"
#   }
# }
#
#
#
#
#
#
#
#
#
# resource "helm_release" "external-dns" {
#   name       = "external-dns"
#   repository = "https://kubernetes-sigs.github.io/external-dns/"
#   chart      = "external-dns"
#   namespace  = "kube-system"
#
#   wait    = true
#   timeout = 600
#
#   values = [
#     yamlencode({
#       serviceAccount = {
#         create = true
#         name   = "external-dns"
#       }
#       provider     = "aws"
#       policy       = "upsert-only"
#       registry     = "txt"
#       txtOwnerId   = "mikey"
#       domainFilters = ["mikeydevops1.online"]
#       sources      = ["ingress", "service"]
#       aws = {
#         zoneType = "public"
#       }
#       logLevel  = "info"
#       interval  = "1m"
#     })
#   ]
#
#   depends_on = [
#
#     null_resource.kubeconfig,
#   ]
#
#
# }
#
#
#
#
# # resource "null_resource" "wait_ingress_ready" {
# #   depends_on = [helm_release.ingress]
# #
# #   provisioner "local-exec" {
# #     command = <<-EOT
# #       set -euo pipefail
# #
# #       # 1) Controller up
# #       kubectl -n ingress-nginx wait deploy/ingress-nginx-controller \
# #         --for=condition=Available=True --timeout=5m
# #
# #       # 2) Admission jobs completed (names used by the official chart)
# #       kubectl -n ingress-nginx wait job/ingress-nginx-admission-create \
# #         --for=condition=complete --timeout=5m || true
# #       kubectl -n ingress-nginx wait job/ingress-nginx-admission-patch \
# #         --for=condition=complete --timeout=5m || true
# #
# #       # 3) Webhook object exists and has CABundle populated (best-effort check)
# #       kubectl get validatingwebhookconfiguration ingress-nginx-admission >/dev/null 2>&1 || true
# #     EOT
# #   }
# # }
# #
# resource "null_resource" "nginx_issuer" {
#   depends_on = [null_resource.kubeconfig, helm_release.cert-manager,null_resource.cert-manager-cluster-issuer,helm_release.external-dns,helm_release.ingress]
#
#   provisioner "local-exec" {
#     command = "kubectl apply -f ${path.module}/helmconfig/nginx-ingress-setup.yml"
#   }
#
#
# }
#
#
#
# resource "helm_release" "argocd" {
#   depends_on = [null_resource.kubeconfig, helm_release.external-dns, helm_release.ingress, helm_release.cert-manager]
#
#   name             = "argocd"
#   repository       = "https://argoproj.github.io/argo-helm"
#   chart            = "argo-cd"
#   namespace        = "argocd"
#   create_namespace = true
#   wait             = false
#
#   # set = [{
#   #   name  = "global.domain"
#   #   value = "learn-argocd-dev.mikeydevops1.online"
#   # }]
#
#   values = [
#     file("${path.module}/helmconfig/argocd.yml")
#   ]
# }
#
# resource "helm_release" "external_secrets_operator" {
#   name       = "external-secrets"
#   repository = "https://charts.external-secrets.io"
#   chart      = "external-secrets"
#   version    = "0.9.17" # or check latest below
#
#   # optional: values.yaml-style customization
#   values = [
#     yamlencode({
#       installCRDs = true
#       serviceAccount = {
#         create = true
#       }
#       webhook = {
#         certManager = {
#           enabled = false
#         }
#       }
#     })
#   ]
# }
#
#
#
# # 1) EKS managed add-on (NO service_account_role_arn for Pod Identity)
# resource "aws_eks_addon" "ebs_csi" {
#
#   cluster_name = var.cluster_name
#   addon_name   = "aws-ebs-csi-driver"
#   # addon_version = "v1.30.0-eksbuild.1" # optional pin
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   depends_on = [
#     aws_eks_pod_identity_association.ebs_csi
#   ]
# }
#
# # 2) IAM role trusted for Pod Identity (NOT IRSA)
# data "aws_iam_policy_document" "ebs_csi_pod_identity_trust" {
#   statement {
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }
#     actions = ["sts:AssumeRole","sts:TagSession"]
#   }
# }
#
# resource "aws_iam_role" "ebs_csi_pi" {
#   name               = "EKS_EBS_CSI_PodIdentityRole"
#   assume_role_policy = data.aws_iam_policy_document.ebs_csi_pod_identity_trust.json
# }
#
# data "aws_iam_policy" "ebs_csi" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }
#
# resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
#   role       = aws_iam_role.ebs_csi_pi.name
#   policy_arn = data.aws_iam_policy.ebs_csi.arn
# }
#
# # 3) Bind the role to the add-on's controller SA via Pod Identity
# resource "aws_eks_pod_identity_association" "ebs_csi" {
#   cluster_name    = var.cluster_name
#   namespace       = "kube-system"
#   service_account = "ebs-csi-controller-sa"
#   role_arn        = aws_iam_role.ebs_csi_pi.arn
#   depends_on      = [aws_iam_role_policy_attachment.ebs_csi_attach]  # wait until SA exists
# }
#
#
# resource "helm_release" "kube-prometheus-stack" {
#   depends_on = [null_resource.kubeconfig, helm_release.ingress, helm_release.cert-manager]
#   name       = "kube-prom-stack"
#   repository = "https://prometheus-community.github.io/helm-charts"
#   chart      = "kube-prometheus-stack"
#   version   = "79.1.1"   # or whatever `helm status` shows
#   wait      = true
#   atomic    = true
#   timeout   = 1200
#   # values = [templatefile("${path.module}/helm-config/prom-stack-template.yml", {
#   #   SMTP_user_name = data.vault_generic_secret.smtp.data["username"]
#   #   SMTP_password  = data.vault_generic_secret.smtp.data["password"]
#   # })]
#   values = [
#     file("${path.module}/helmconfig/prograf.yaml")
#   ]
# }
# # resource "null_resource" "nginx_issuer" {
# #   depends_on = [ helm_release.kube-prometheus-stack]
# #
# #   provisioner "local-exec" {
# #     command = "kubectl apply -f ${path.module}/helmconfig/servicemonitor.yaml"
# #   }
# #
# #
# # }
# # resource "helm_release" "cluster-autoscaler" {
# #
# #   depends_on = [null_resource.kubeconfig]
# #   name       = "cluster-autoscaler"
# #   repository = "https://kubernetes.github.io/autoscaler"
# #   chart      = "cluster-autoscaler"
# #   namespace  = "kube-system"
# #   wait       = "false"
# #
# #   set = [{
# #     name  = "autoDiscovery.clusterName"
# #     value = var.cluster_name
# #   },
# #   {
# #     name  = "awsRegion"
# #     value = "us-east-1"
# #   }]
# # }
#
# # resource "helm_release" "wave-config-reloader" {
# #
# #   depends_on = [null_resource.kubeconfig]
# #   name       = "wave"
# #   repository = "https://wave-k8s.github.io/wave/"
# #   chart      = "wave"
# #   namespace  = "kube-system"
# #   wait       = "false"
# #
# #   set=[ {
# #     name  = "webhooks.enabled"
# #     value = true
# #   }]
# # }
# #
# # resource "helm_release" "istio-base" {
# #   depends_on = [
# #     null_resource.kubeconfig
# #   ]
# #
# #   name             = "istio-base"
# #   repository       = "https://istio-release.storage.googleapis.com/charts"
# #   chart            = "base"
# #   namespace        = "istio-system"
# #   create_namespace = true
# # }
# #
# # resource "helm_release" "istiod" {
# #   depends_on = [
# #     null_resource.kubeconfig,
# #     helm_release.istio-base
# #   ]
# #
# #   name             = "istiod"
# #   repository       = "https://istio-release.storage.googleapis.com/charts"
# #   chart            = "istiod"
# #   namespace        = "istio-system"
# #   create_namespace = true
# #   version = "1.25"
# # }
# #
# # resource "null_resource" "kiali" {
# #   depends_on = [
# #     null_resource.kubeconfig,
# #     helm_release.istiod
# #   ]
# #   provisioner "local-exec" {
# #     command = <<EOF
# # kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/kiali.yaml
# # kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/prometheus.yaml
# # kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/grafana.yaml
# # kubectl apply -f - <<EOK
# # apiVersion: networking.k8s.io/v1
# # kind: Ingress
# # metadata:
# #   annotations:
# #     nginx.ingress.kubernetes.io/backend-protocol: HTTP
# #     nginx.ingress.kubernetes.io/secure-backends: "false"
# #   name: kiali
# #   namespace: istio-system
# # spec:
# #   ingressClassName: nginx
# #   rules:
# #   - host: kiali-dev.mikeydevops1.online
# #     http:
# #       paths:
# #       - backend:
# #           service:
# #             name: kiali
# #             port:
# #               number: 20001
# #         path: /kiali
# #         pathType: Prefix
# # EOK
# # EOF
# #   }
# # }