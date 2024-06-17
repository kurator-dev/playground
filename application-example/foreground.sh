#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# variable define
kind_version=v0.17.0
host_cluster_ip=172.30.1.2 #host node where Kurator is located
member_cluster_ip=172.30.2.2
local_ip=127.0.0.1
KUBECONFIG_PATH=${KUBECONFIG_PATH:-"${HOME}/.kube"}

function installKind() {
    cat << EOF > installKind.sh
    wget https://github.com/kubernetes-sigs/kind/releases/download/${kind_version}/kind-linux-amd64
    chmod +x kind-linux-amd64
    sudo mv kind-linux-amd64 /usr/local/bin/kind
EOF
}

function createCluster() {
    cat << EOF > createCluster.sh
    kind create cluster --name=member1 --config=cluster1.yaml
    mv $HOME/.kube/config ~/config-member1
    kind create cluster --name=member2 --config=cluster2.yaml
    mv $HOME/.kube/config config-member2
    KUBECONFIG=~/config-member1:~/config-member2 kubectl config view --merge --flatten >> ${KUBECONFIG_PATH}/config
    # modify ip
    sed -i "s/${local_ip}/${member_cluster_ip}/g"  config-member1
    scp config-member1 root@${host_cluster_ip}:$HOME/.kube/config-member1
    sed -i "s/${local_ip}/${member_cluster_ip}/g"  config-member2
    scp config-member2 root@${host_cluster_ip}:$HOME/.kube/config-member2
EOF
}

function cluster1Config() {
    touch cluster1.yaml
    cat << EOF > cluster1.yaml
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    networking:
      apiServerAddress: "${member_cluster_ip}"
      apiServerPort: 6443
EOF
}

function cluster2Config() {
    touch cluster2.yaml
    cat << EOF > cluster2.yaml 
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    networking:
      apiServerAddress: "${member_cluster_ip}"
      apiServerPort: 6444
EOF
}

function copyConfigFilesToNode() {
    scp installKind.sh root@${member_cluster_ip}:~
    scp createCluster.sh root@${member_cluster_ip}:~
    scp cluster1.yaml root@${member_cluster_ip}:~
    scp cluster2.yaml root@${member_cluster_ip}:~
}

function fluxcd_values() {
    touch fluxcd.yaml
    cat << EOF > fluxcd.yaml 
    imageAutomationController:
      create: false
    imageReflectionController: 
      create: false
    notificationController:
      create: false
EOF
}

function attachcluster() {
    touch attachcluster.yaml
    cat << EOF > attachcluster.yaml 
apiVersion: cluster.kurator.dev/v1alpha1
kind: AttachedCluster
metadata: 
  name: kurator-member1
  namespace: default
spec:
  kubeconfig:
    name: kurator-member1
    key: kurator-member1.config
---
apiVersion: cluster.kurator.dev/v1alpha1
kind: AttachedCluster
metadata:
  name: kurator-member2
  namespace: default
spec:
  kubeconfig:
    name: kurator-member2
    key: kurator-member2.config
EOF
}

function fleet() {
    touch fleet.yaml
    cat << EOF > fleet.yaml 
    apiVersion: fleet.kurator.dev/v1alpha1
    kind: Fleet 
    metadata:
      name: quickstart
      namespace: default
    spec:
      clusters:
        - name: kurator-member1 
          kind: AttachedCluster
        - name: kurator-member2
          kind: AttachedCluster
EOF
}

function install_kurator() {
    # install Helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 700 get_helm.sh && ./get_helm.sh
    helm repo add jetstack https://charts.jetstack.io && helm repo update
    kubectl create namespace cert-manager
    helm install -n cert-manager cert-manager jetstack/cert-manager --set installCRDs=true
    helm repo add fluxcd-community https://fluxcd-community.github.io/helm-charts
    cat fluxcd.yaml | helm install fluxcd fluxcd-community/flux2 --version 2.7.0 -n fluxcd-system --create-namespace -f -
    helm repo add kurator https://kurator-dev.github.io/helm-charts && helm repo update
    # install kurator
    helm install --create-namespace  kurator-cluster-operator kurator/cluster-operator --version=0.6.0 -n kurator-system
    helm install --create-namespace  kurator-fleet-manager kurator/fleet-manager --version=0.6.0 -n kurator-system
}

kubectl delete node node01
kubectl taint node controlplane node-role.kubernetes.io/control-plane:NoSchedule-

# install kind and create member clusters
installKind
createCluster
cluster1Config
cluster2Config
fluxcd_values
copyConfigFilesToNode

install_kurator
attachcluster
fleet

# create cluster in node01 machine
ssh root@${member_cluster_ip} "bash ~/installKind.sh" &
sleep 10
ssh root@${member_cluster_ip} "bash ~/createCluster.sh"

# clean screen 
clear