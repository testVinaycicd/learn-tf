infra:
	git pull
	cd terraform
	terraform init
	terraform plan \
    -var "vpc_id=vpc-00dba36961960f2b1" -var "alb_subnet_ids=["subnet-092b98e6a5c96c8ff","subnet-071a6a6e6bfe92251"]" \
    -var "ec2_subnet_id=subnet-02b12a0f8ad51477d" \
    -var "route53_zone_id=Z09180393TY9K7UQDKE5E" \
    terraform apply \
    -var "vpc_id=vpc-xxxx" \
    -var "alb_subnet_ids=[\"subnet-a\",\"subnet-b\"]" \
    -var "ec2_subnet_id=subnet-private" \
    -var "route53_zone_id=Z09180393TY9K7UQDKE5E" \
    -auto-approve
