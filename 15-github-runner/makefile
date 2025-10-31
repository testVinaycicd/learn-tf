#infra:
#	git pull
#	terraform init
#	terraform apply -auto-approve

ansible:
	git pull
	export PATH=/opt/ansible-venv/bin:$PATH
	ansible-playbook -i learn-github-runner-internal.mikeydevops1.online, setup-tool.yaml -e ansible_user=ec2-user -e ansible_password=DevOps321 -e tool_name=$(tool_name) -e vault_token=$(vault_token)
	#ansible-playbook -i $(tool_name).mikeydevops1.online, setup-tool.yml -e ansible_user=ec2-user -e ansible_password=DevOps321 -e tool_name=$(tool_name)


debug:
	git pull
	ansible-playbook -i learn-github-runner-internal.mikeydevops1.online, setup-tool.yaml -e ansible_user=ec2-user -e ansible_password=DevOps321 -e tool_name=$(tool_name) -e vault_token=$(vault_token) -vvv
	#ansible-playbook -i $(tool_name).mikeydevops1.online, setup-tool.yml -e ansible_user=ec2-user -e ansible_password=DevOps321 -e tool_name=$(tool_name)
