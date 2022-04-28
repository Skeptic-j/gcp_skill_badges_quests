# Monitor Environments with Managed Service for Prometheus: Challenge Lab
[Link to challenge lab](https://www.cloudskillsboost.google/focuses/33337?parent=catalog)


## Objectives
- Deploy the Managed Service for Prometheus
- Create a self managed data collection for scraping metrics
- Deploy an application to query metrics

---
## 1. Deploy GKE Cluster
Create a cluster for deploying prometheus and application sample, get credentials to connect to cluster.
```
gcloud beta container clusters create gmp-cluster --num-nodes=1 --zone us-central1-f --enable-managed-prometheus
gcloud container clusters get-credentials gmp-cluster --zone=us-central1-f
```
Then create a namespace for the test environment
```
kubectl create ns gmp-test
```

---
## 2. Deploy a managed collection
we'll use the collection from GCP's github repo.
```
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/examples/pod-monitoring.yaml
kubectl get podmonitoring -n gmp-test
```

---
## 3. Deploy example application
The example application repo link is given by the lab.
```
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/examples/example-app.yaml
kubectl get deployments -n gmp-test
```

---
## 4. Filter exported metrics
Edit the configuration file to add in filter metrics.
```
kubectl -n gmp-public edit operatorconfig config
```

add in line after the line "ApiVersion:..."
```
collection:
  filter:
    matchOneOf:
    - '{job="prom-example"}'
    - '{__name__=~"job:.+"}'
```

Copy the contents of operatorconfig and paste inside the `config.yaml` file,
```
kubectl -n gmp-public get operatorconfig config --output="yaml" > op-config.yaml
```

Upload config file to verify
```
export PROJECT=$(gcloud config get-value project)
gsutil mb -p $PROJECT gs://$PROJECT
gsutil cp op-config.yaml gs://$PROJECT
gsutil -m acl set -R -a public-read gs://$PROJECT
```

---
## END
---