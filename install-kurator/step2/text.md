## Preparation 

### Install Helm

RUN `curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 700 get_helm.sh && ./get_helm.sh`{{exec}}

### Preparing the environment

RUN `helm repo add jetstack https://charts.jetstack.io && helm repo update`{{exec}}

RUN `kubectl create namespace cert-manager`{{exec}}

RUN `helm install -n cert-manager cert-manager jetstack/cert-manager --set installCRDs=true`{{exec}}

Run `helm repo add fluxcd-community https://fluxcd-community.github.io/helm-charts`{{exec}}

### Install fluxcd

RUN `cat fluxcd.yaml | helm install fluxcd fluxcd-community/flux2 --version 2.7.0 -n fluxcd-system --create-namespace -f -`{{exec}}
