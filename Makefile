INFRA=infra
TFVARS=$(INFRA)/dev.tfvars
REGION=us-east-1

dev-up:
	cd $(INFRA) && terraform init -reconfigure
	cd $(INFRA) && terraform apply -var-file=$(TFVARS)

ingress-on:
	kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f k8s/feedbackhub/hello.yaml
	kubectl apply -f k8s/feedbackhub/ingress-dev.yaml
	@echo "Waiting for hello deployment to be Available..."
	kubectl -n dev wait --for=condition=Available --timeout=180s deploy/hello || true
	kubectl -n dev get ingress

ingress-off:
	-kubectl -n dev delete ingress feedbackhub-dev
	-kubectl -n dev delete svc hello
	-kubectl -n dev delete deploy hello

dev-down:
	$(MAKE) ingress-off
	cd $(INFRA) && terraform destroy -var-file=$(TFVARS)

check-lb:
	aws elbv2 describe-load-balancers --region $(REGION) --no-cli-pager \
	  --query "LoadBalancers[?contains(LoadBalancerName, 'k8s')].[LoadBalancerName,DNSName,State.Code]" --output table
