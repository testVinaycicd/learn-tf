terraform:
	git pull
	terraform init
	terraform plan -var-file=env-dev/state.tfvars
	terraform apply -var-file=env-dev/state.tfvars -auto-approve