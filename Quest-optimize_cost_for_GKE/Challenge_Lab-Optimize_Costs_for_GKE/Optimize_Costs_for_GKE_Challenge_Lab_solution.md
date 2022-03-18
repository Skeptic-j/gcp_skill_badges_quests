# Quest 6 - Optimize Costs for Google Kubernetes Engine: Challenge Lab
[Link to challenge lab](https://www.cloudskillsboost.google/focuses/16327?parent=catalog)<br>

## Main Objectives to achieve in this challenge lab:
- Deploying an app on a multi-tenant cluster
- Migrating cluster workloads to an optimized node pool
- Rolling out an application update while maintaining cluster availability
- Cluster and pod autoscaling

## Some given standard guidelines
- Create the cluster in the `us-central1` region

- The naming scheme is `team-resource-number`, e.g. a cluster could be named `onlineboutique-cluster-764`

- For your initial cluster, start with machine size `n1-standard-2 (2 vCPU, 8G memory)`

- Set your cluster to use the **rapid** `release-channel`.

- [Kubectl Cheatsheet always comes handy](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## Export environment variables
```
export CLUSTERNAME=onlineboutique-cluster-764
export POOLNAME=optimized-pool-2640
export MAXREP=10
export REGION=us-central1
export ZONE=us-central1-b
echo $CLUSTERNAME
echo $POOLNAME
echo $MAXREP
echo $REGION
echo $ZONE
```
<br>

---
## Task 1: Create our cluster and deploy our app
1. Create **zonal cluster** with 2 nodes 
```
gcloud config set compute/region $REGION
gcloud container clusters create $CLUSTERNAME --num-nodes=2 --node-locations=$ZONE --machine-type=n1-standard-2 --release-channel=rapid
gcloud container clusters get-credentials $CLUSTERNAME      #depends if you're managing multiple different clusters
```

2. Enable kubectl prompt & Create two separate namespace `dev` and `prod`.
```
source <(kubectl completion bash)
kubectl get namespace
kubectl create namespace dev
kubectl create namespace prod
kubectl get namespace
```

3. Deploy application in `dev` namespace.
```
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
cd microservices-demo
kubectl apply -f ./release/kubernetes-manifests.yaml --namespace dev
kubectl get deployments --namespace=dev
```

4. Check that your **OnlineBoutique** store is up and running by navigating to the IP address for your **frontend-external** service.
```
kubectl get services --namespace=dev
```
<br>

---
## Task 2: Migrate to an Optimized Nodepool
1. Create a new node pool name `optimized-pool-2640` with **custom-2-3584** as the machine type. Set the number of **nodes to 2**.
```
gcloud container node-pools create $POOLNAME --cluster=$CLUSTERNAME --machine-type=custom-2-3584 --num-nodes=2
gcloud container node-pools list --cluster=$CLUSTERNAME
```

2. Migrate your application's deployments to the new nodepool by cordoning off and draining `default-pool`. Delete the default-pool once the deployments have safely migrated. Cordon first:
```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
  kubectl cordon "$node";
done
```
Then drain,
```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
  kubectl drain --force --ignore-daemonsets --grace-period=10 "$node";
done
kubectl get pods -o=wide --namespace=dev
kubectl top node
```

3. Delete default-pool after successfully draining it.
```
gcloud container node-pools delete default-pool --cluster=$CLUSTERNAME
```
<br>

---
## Task 3: Apply a Frontend Update
1. Create pod disruption budget **onlineboutique-frontend-pdb** for **frontend** deployment.
```
kubectl create poddisruptionbudget onlineboutique-frontend-pdb --namespace=dev --selector app=frontend --min-available 1
kubectl get poddisruptionbudget.policy --namespace=dev
```

To update the frontend image, we have 3 options here and choose one either in 2a, 2b, and 2c.<br>

2a. Open any editor and Edit image used in `microservices-demo/kubernetes-manifest/frontend.yaml` to the given new image. Change image from `frontend` to `gcr.io/qwiklabs-resources/onlineboutique-frontend:v2.1`. Also add `imagePullPolicy` to **Always**.
```
image: gcr.io/qwiklabs-resources/onlineboutique-frontend:v2.1
imagePullPolicy: Always
```
Then apply the changes.
```
kubectl apply -f microservices-demo/kubernetes-manifest/frontend.yaml
```

2b. Alternative method with deployment rollout:
```
kubectl set image deployment/frontend --namespace=dev server=gcr.io/qwiklabs-resources/onlineboutique-frontend:v2.1
kubectl rollout status deployment frontend --namespace=dev
kubectl rollout history deployment frontend --namespace=dev
kubectl get deployment frontend --namespace=dev
```

2c. This is the right command to get the green checkmark. Change image from `frontend` to `gcr.io/qwiklabs-resources/onlineboutique-frontend:v2.1`. Also add `imagePullPolicy` to **Always** in the VI editor
```
kubectl edit deployment/frontend --namespace=dev
```
save and exit `:x!` VI editor
<br>

---
## Task 4: Autoscale from Estimated Traffic
1. Configure the k8s cluster to scale automatically during large traffic spikes. Use HPA on frontend deployment:

|option|target|
|-|-|
|target cpu percentage|50|
|min replicas|1|
|max replicas|10|

```
kubectl autoscale deployment frontend --namespace=dev --cpu-percent=50 --min=1 --max=$MAXREP
kubectl get hpa --namespace=dev
```
2. Update **cluster autoscaler** to scale between **1 node minimum** and **6 nodes maximum**.
```
gcloud beta container clusters update $CLUSTERNAME --enable-autoscaling --min-nodes 1 --max-nodes 6 --region=$REGION
```

3. Run load test. Increase traffic with built in load generator on `loadgenerator` pod
```
export YOUR_FRONTEND_EXTERNAL_IP=104.198.177.60
kubectl exec $(kubectl get pod --namespace=dev | grep 'loadgenerator' | cut -f1 -d ' ') -it --namespace=dev -- bash -c "export USERS=8000; locust --host="http://$YOUR_FRONTEND_EXTERNAL_IP" --headless -u "8000" 2>&1"
```
Now, observe your **Workloads** and monitor how your cluster handles the traffic spike.

You should see your `recommendationservice` crashing or, at least, heavily struggling from the increased demand.

Apply ***horizontal pod autoscaling*** to your recommendationservice deployment. Scale based off a target cpu percentage of 50 and set the pod scaling between 1 minimum and 5 maximum.
```
kubectl autoscale deployment recommendationservice --namespace=dev --cpu-percent=50 --min=1 --max=5
kubectl get hpa --namespace=dev
```
<br>

---
## Task 5. Optimize with Node Auto Provisioning
Last step, inspect some of your other workloads and try to optimize them by applying autoscaling towards the proper resource metric. Adjust the memory depending on the load.
```
gcloud container clusters update $CLUSTERNAME \
    --region=$REGION \
    --enable-autoprovisioning \
    --min-cpu 1 \
    --min-memory 2 \
    --max-cpu 45 \
    --max-memory 200
```

---
##END
---