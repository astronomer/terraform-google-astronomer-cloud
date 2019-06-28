.PHONY: clean update-modules apply destroy

clean:
	rm -rf .terraform

update-modules:
	rm -rf .terraform
	terraform get

apply:
	bash deploy.sh terraform.tfvars

destroy:
	export https_proxy=http://127.0.0.1:1234
    export no_proxy="googleapis.com,.google.com,metadata,.googleapis.com,github.com,.github.com"
    terraform destroy -var-file=terraform.tfvars
    unset no_proxy https_proxy
