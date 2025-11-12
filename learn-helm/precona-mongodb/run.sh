#image_tag=$1

PASSWORD=$(kubectl get secrets -n argocd argocd-initial-admin-secret -o json | jq .data.password|xargs | base64 --decode)
argocd login learn-argocd-dev.mikeydevops1.online --grpc-web --insecure --username admin --password $PASSWORD


# Operator
argocd app create psmdb-operator \
--project default \
--repo https://github.com/testVinaycicd/learn-tf.git \
--path learn-helm/precona-mongodb  \
--dest-server https://kubernetes.default.svc \
--dest-namespace default \
--sync-policy automated --self-heal --auto-prune --revision main \
--helm-set image.repository=percona/percona-server-mongodb-operator \
--helm-set image.tag=1.16.1 \
--helm-set operatorImage.repository=percona/percona-server-mongodb-operator \
--helm-set operatorImage.tag=1.16.1


# Cluster
