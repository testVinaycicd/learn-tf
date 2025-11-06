component_name=$1
imageTag=$2

PASSWORD=$(kubectl get secrets -n argocd argocd-initial-admin-secret -o json | jq .data.password|xargs | base64 --decode)
argocd login learn-argocd-dev.mikeydevops1.online --grpc-web --insecure --username admin --password $PASSWORD


#argocd app create ${component_name} --upsert --repo https://github.com/testVinaycicd/learn-tf.git --path "learn-helm/new helm" --dest-namespace default --dest-server https://kubernetes.default.svc --values env-${env}/${component_name}.yaml --helm-set imageTag=${imageTag}
argocd app create "${component_name}" --project default --repo https://github.com/testVinaycicd/learn-tf.git --path "learn-helm/new helm" --revision main --dest-server https://kubernetes.default.svc --dest-namespace default --values "env-values-dev/${component_name}.yaml" --sync-policy automated --self-heal  --auto-prune --helm-set "image.tag=${image_tag}"
argocd app sync "${component_name}"  --grpc-web




#argocd login a5d5d3fd81f7a460b806e2337d5aa0c6-1632824844.us-east-1.elb.amazonaws.com --username admin --password jfryO2UWtkPeY8di


#argocd app create frontend --project default --repo https://github.com/testVinaycicd/learn-tf.git --path "learn-helm/new helm" --revision main --dest-server https://kubernetes.default.svc --dest-namespace default --values env-values-dev/frontend.yaml --sync-policy automated --self-heal  --auto-prune
