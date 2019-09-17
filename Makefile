.PHONY: clean update-modules apply destroy

clean:
	rm -rf .terraform

update-modules:
	rm -rf .terraform
	terraform get

apply:
	bash deploy.sh terraform.tfvars

destroy:
	bash destroy.sh terraform.tfvars
