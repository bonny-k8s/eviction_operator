# EvictionOperator

The eviction operator allows workloads to _opt-in_ to being evicted after some amount of time.

The main purpose of this operator is to allow pods that have been scheduled on _nonpreferred_ nodes (via nodeAffinity) to evict themselves in hopes that the Kubernetes scheduler will place them on a preferred node.

## Installation

- [ ] quay image link
- [ ] configuration
- [ ] kustomize yaml

## Usage

This operator functions in two modes:

- `all` will evict all matching pods no matter what node they are on
- `nonpreferred` will evict any matching pod on a node that _does not_ meet the pod's preferred `nodeAffinity`.

`all` example resource:

This would evict _any_ pod matching the label `app:nginx` after 300 seconds.

```yaml
apiVersion: eviction-operator.bonny.run/v1
kind: EvictionPolicy
metadata:
  name: all-nginx
spec:
  mode: all # nonpreferred; evict off all nodes or only nonpreferred nodes
  maxLifetime: 300 # in seconds
  selector:
    matchLabels:
      app: nginx
```

`nonpreferred` example resource:

First, workloads will need to specify a preferred `nodeAffinity`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 10
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 1
              preference:
                matchExpressions:
                  - key: node-type
                    operator: In
                    values:
                      - preemptible
      containers:
        - name: nginx
          image: nginx:1.7.9
          ports:
            - containerPort: 80
```

Then an `EvictionPolicy` can be added to match all pods on nonpreferred nodes.

```yaml
apiVersion: eviction-operator.bonny.run/v1
kind: EvictionPolicy
metadata:
  name: nonpreferred-nodes-nginx
spec:
  mode: nonpreferred
  maxLifetime: 300 # in seconds
  selector:
    matchLabels:
      app: nginx
```
