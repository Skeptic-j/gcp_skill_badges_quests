setup helm to manage and deploy packages into your cluster<br>
[Guide to helm](https://helm.sh/docs/intro/using_helm/)<br>
[How Jenkins works on GKE](https://cloud.google.com/architecture/jenkins-on-kubernetes-engine)

```
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

setting up jenkins with helm
```
helm install cd stable/jenkins -f jenkins/values.yaml --version 1.2.2 --wait
```

Port forward to Jenkins UI
```
export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/component=jenkins-master" -l "app.kubernetes.io/instance=cd" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 8080:8080 >> /dev/null &
kubectl get svc
```

use `admin` and password
```
printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```
[Jenkins CLI Guide](https://www.jenkins.io/doc/book/managing/cli/)
