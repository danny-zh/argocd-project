.PHONY: install-argocd
.SHELL: /bin/bash

LATEST_ARGOCD_URL="https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/stable/manifests/install.yaml"
ARGOCD_EXPOSED_PORT=8080
IP_ADDRESS=$(shell hostname -I | awk '{print $$1}')

install-latest-argocd:
	@echo "Installing latest version of ArgoCD..."
	@kubectl apply -f argocd_namespace.yaml
	@kubectl apply --server-side --force-conflicts -n argocd -f $(LATEST_ARGOCD_URL)
	@echo "ArgoCD installation complete."

print-argocd-server-url:
	@echo "ArgoCD server URL: https://$(IP_ADDRESS):$(ARGOCD_EXPOSED_PORT)"

expose-argocd-server:
	@echo "Exposing ArgoCD server..."
	@nohup kubectl port-forward svc/argocd-server -n argocd --address $(IP_ADDRESS) $(ARGOCD_EXPOSED_PORT):443 > /dev/null 2>&1 &
	@echo "ArgoCD server exposed at https://$(IP_ADDRESS):$(ARGOCD_EXPOSED_PORT)"

create-initial-password:
	@echo "Creating initial ArgoCD admin password..."
	@argocd admin initial-password -n argocd
	@echo "Initial ArgoCD admin password created."

get-argocd-admin-password:
	@echo "Retrieving ArgoCD admin password..."
	@kubectl get secret -n argocd argocd-initial-admin-secret -o template={{.data.password}} | base64 -d && echo

update-coredns-configmap:
	@echo "Updating CoreDNS ConfigMap to include vagrant-cluster"
	@kubectl -n kube-system apply -f coredns-configmap.yaml
	@kubectl rollout restart deployment coredns -n kube-system
	@echo "CoreDNS ConfigMap updated."