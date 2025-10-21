install:
	helm upgrade -i frontend . -f env-values-dev/frontend.yaml
	helm upgrade -i catalogue . -f env-values-dev/catalogue.yaml
	helm upgrade -i mongodb . -f env-values-dev/mongodb.yaml
	helm upgrade -i user . -f env-values-dev/user.yaml


uninstall:
	helm uninstall mongodb
	helm uninstall frontend
	helm uninstall catalogue
	helm uninstall user