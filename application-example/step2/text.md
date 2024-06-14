## Join with Fleet

To join the AttachedClusters into a fleet, create the yaml like this:

```console
cat <<EOF | kubectl apply -f -
apiVersion: fleet.kurator.dev/v1alpha1
kind: Fleet 
metadata:
  name: quickstart
  namespace: default
spec:
  clusters:
    # add your AttachedCluster here
    - name: kurator-member1 
      kind: AttachedCluster
    - name: kurator-member2
      kind: AttachedCluster
EOF
```

RUN `kubectl apply -f fleet.yaml`{{exec}}

## Check fleet status

RUN `kubectl get fleet -A`{{exec}}