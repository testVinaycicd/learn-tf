terraform:
	git pull
	terraform init -backend-config=env-dev/s3-dev.tfvars
	terraform plan -var-file=env-dev/state.tfvars
	terraform apply -var-file=env-dev/state.tfvars -auto-approve

destroy:
	terraform destroy -var-file=env-dev/state.tfvars -auto-approve