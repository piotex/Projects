

```
minikube start --nodes=3 -p mycluster --driver=docker

kubectl get nodes

kubectl port-forward svc/nginx-service 8088:8080

minikube stop
```

```
kubectl exec -it nginx -- /bin/bash
cat /usr/share/nginx/html/index.html
```

```
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```