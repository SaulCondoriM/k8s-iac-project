# k8s-on-digital-ocean

Create a Kubernetes cluster [here](https://cloud.digitalocean.com/kubernetes/clusters?i=ebdc0a).

Add the cluster to your Kubeconfig
```
doctl kubernetes cluster list
doctl kubernetes cluster kubeconfig save 78287d0e-a0c4-4a9a-9dd5-a2cafc793ac7
```

Install ingress-nginx controller
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace --set controller.publishService.enabled=true
```

Create the CSI token secret in kube-system

Deploy the CSI controller and sidecar
```
kubectl apply -fhttps://raw.githubusercontent.com/digitalocean/csi-digitalocean/master/deploy/kubernetes/releases/csi-digitalocean-v4.9.0/{crds.yaml,driver.yaml,snapshot-controller.yaml}
```

Add postgres chart (bitnami)
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Create PVCs

Install postgres helm chart
```
helm install postgresdb bitnami/postgresql --set persistence.existingClaim=postgresql-pv-claim --set volumePermissions.enabled=true
```

Get postgres password
```
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgresdb-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
echo POSTGRES_PASSWORD
```

Create postgres connection string secret

Deploy the application

Validate that the application works
```
kubectl port-forward svc/do-sample-app-service 8080:8080
```

Deploy the ingress

Point DNS CNAME to the ingress IP address

Success :)


Next steps:
- Install Cert Manager
- Install Monitoring solution
- Install Logging solution
- Improve security
- Set up CI/CD, Helm chart, etc