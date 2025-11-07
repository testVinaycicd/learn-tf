terraform:
	git pull
	terraform init -backend-config=env-dev/s3-dev.tfvars
	terraform plan -var-file=env-dev/state.tfvars
	terraform apply -var-file=env-dev/state.tfvars -auto-approve -var vault_token=$(vault_token)

destroy:
	terraform destroy -var-file=env-dev/state.tfvars -auto-approve -var vault_token=$(vault_token)