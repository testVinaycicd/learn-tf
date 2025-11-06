install:
	helm upgrade -i frontend . -f env-values-dev/frontend.yaml
	helm upgrade -i catalogue . -f env-values-dev/catalogue.yaml
	helm upgrade -i mongodb . -f env-values-dev/mongodb.yaml

template:
	helm template ${component} . -f env-values-dev/${component}.yaml


uninstall:
	helm uninstall mongodb
	helm uninstall frontend
	helm uninstall catalogue
