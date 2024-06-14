## Kurator Application

Kurator offers a unified system for distributing applications across multiple clusters, powered by Fleet.

By making use of the GitOps approach through FluxCD, Kurator automates the process of syncing and deploying applications. This makes the entire procedure quicker and more precise

Built to be flexible and responsive, Kurator’s distribution system is specially designed to accommodate various business and cluster demands.

### Create an example application

Here is the content of example application resource. The YAML configuration of the example application outlines its source, synchronization policy, and other key settings. This includes the gitRepository as its source and two kustomization syncPolicies referring to a fleet that contains two attachedClusters

```console
echo 'apiVersion: apps.kurator.dev/v1alpha1
kind: Application
metadata:
  name: gitrepo-kustomization-demo
  namespace: default
spec:
  source:
    gitRepository:
      interval: 3m0s
      ref:
        branch: master
      timeout: 1m0s
      url: https://github.com/stefanprodan/podinfo
  syncPolicies:
    - destination:
        fleet: quickstart
      kustomization:
        interval: 5m0s
        path: ./deploy/webapp
        prune: true
        timeout: 2m0s
    - destination:
        fleet: quickstart
      kustomization:
        targetNamespace: default
        interval: 5m0s
        path: ./kustomize
        prune: true
        timeout: 2m0s'| kubectl apply -f -
```

RUN `kubectl apply -f https://raw.githubusercontent.com/kurator-dev/kurator/main/examples/application/gitrepo-kustomization-demo.yaml`{{exec}}

### Check Application Status

RUN `kubectl describe application gitrepo-kustomization-demo`{{exec}}

Checking out pods in member clusters

RUN `kubectl get po -A --kubeconfig=/root/.kube/config-member1`{{exec}}

RUN `kubectl get po -A --kubeconfig=/root/.kube/config-member2`{{exec}}
