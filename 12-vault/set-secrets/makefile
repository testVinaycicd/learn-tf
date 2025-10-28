set-auth:
	git pull
	terraform init
	terraform plan -var vault_addr=${vault_addr} -var vault_token=${vault_token} -var issuer=${issuer} -var k8s_api_server=${k8s_api_server}
	terraform apply -auto-approve -var vault_addr=${vault_addr} -var vault_token=${vault_token} -var issuer=${issuer} -var k8s_api_server=${k8s_api_server}