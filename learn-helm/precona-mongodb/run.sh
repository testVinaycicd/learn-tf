#image_tag=$1

PASSWORD=$(kubectl get secrets -n argocd argocd-initial-admin-secret -o json | jq .data.password|xargs | base64 --decode)
argocd login learn-argocd-dev.mikeydevops1.online --grpc-web --insecure --username admin --password $PASSWORD


# Operator
argocd app create psmdb-operator \
--project default \
--repo https://github.com/testVinaycicd/learn-tf.git \
--path learn-helm/precona-mongodb --revision 1.16.1 \
--dest-server https://kubernetes.default.svc \
--dest-namespace default \
--sync-policy automated --self-heal --auto-prune --revision main \
--helm-set image=percona/percona-server-mongodb-operator:1.16.1 \
--helm-set operatorImage=percona/percona-server-mongodb-operator:1.16.1



# Cluster

#argocd app create psmdb-operator \
#  --upsert \
#  --project default \
#  --repo https://github.com/testVinaycicd/learn-tf.git \
#  --path learn-helm/precona-mongodb psmdb-operator \
#  --revision 1.16.1 \
#  --dest-server https://kubernetes.default.svc \
#  --dest-namespace default \
#  --sync-policy automated --self-heal --auto-prune
#
#
#helm upgrade --install psmdb-operator percona/psmdb-operator \
#  --namespace default --create-namespace \
#  --version 1.16.1 \
#  --set image=percona/percona-server-mongodb-operator:1.16.1 \
#  --set operatorImage=percona/percona-server-mongodb-operator:1.16.1 \
#  --wait
