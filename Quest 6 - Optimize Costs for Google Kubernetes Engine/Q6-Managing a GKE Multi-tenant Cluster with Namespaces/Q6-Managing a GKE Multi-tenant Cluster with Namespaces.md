# Quest 6 - Managing a GKE Multi-tenant Cluster with Namespaces
[link-to-lab](https://www.cloudskillsboost.google/focuses/14861?parent=catalog)

## Summary:
* Create multiple namespaces in a GKE cluster

* Configure role-based access control (RBAC) for namespace access

* Configure Kubernetes resource quotas for fair sharing resources across multiple namespaces

* View and configure monitoring dashboards to view resource usage by namespace

* Generate a GKE metering report in Data Studio for fine grained metrics on resource utilization by namespace

### Setup: Download required files
the required yaml files are prepared
```
gsutil -m cp -r gs://spls/gsp766/gke-qwiklab ~
cd ~/gke-qwiklab
```

### 1. View and Create Namespaces
set default zone and authenticate provided cluster "multi-tenant-cluster"
```
gcloud config set compute/zone us-central1-a && gcloud container clusters get-credentials multi-tenant-cluster
kubectl get namespace
```
Notes for namespaces:
1. default - the default namespace used when no other namespace is specified
2. kube-node-lease - manages the lease objects associated with the heartbeats of each of the cluster's nodes
3. kube-public - to be used for resources that may need to be visible or readable by all users throughout the whole cluster
4. kube-system - used for components created by the Kubernetes system

Note: nodes, persistent volumes, and namespaces themselves do not belong to a namespace
```
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false		#check for non-namespaced items
kubectl get services --namespace=kube-system
```

#### 1.1 Creating New Namespaces
Create namesapce for "team-a" & "team-b", then deploy pods in respective namespace
```
kubectl create namespace team-a && kubectl create namespace team-b
kubectl run app-server --image=centos --namespace=team-a -- sleep infinity && \
kubectl run app-server --image=centos --namespace=team-b -- sleep infinity
kubectl get pods -A
kubectl describe pod app-server --namespace=team-a

# To work exclusively with resources in one namespace, you can set it once in the kubectl context instead of using the --namespace flag for every command:
kubectl config set-context --current --namespace=team-a

# After this, any subsequent commands will be run against the indicated namespace without specifying the --namespace flag:
kubectl describe pod app-server
```

### 2. Access Control in Namespaces
Grant the account the Kubernetes Engine Cluster Viewer role by running the following:
```
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
--member=serviceAccount:team-a-dev@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com  \
--role=roles/container.clusterViewer
```

#### 2.1 Kubernetes RBAC
Creating Role = (resource + verb) with kubectl create in team-a namespace:
```
kubectl create role pod-reader --resource=pods --verb=watch --verb=get --verb=list
kubectl get roles.rbac.authorization.k8s.io -A
```

Similarly created for us in the yaml files, view:
```
cat developer-role.yaml
kubectl create -f developer-role.yaml
kubectl describe roles developer
```

Create role binding to subject. RoleBindings= (Subjects + roleRef)
```
kubectl create rolebinding team-a-developers \
--role=developer --user=team-a-dev@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
kubectl describe rolebindings team-a-developers
```

Download serviceAccount key, upload it, get cluster credentials, Test the role binding
```
gcloud iam service-accounts keys create /tmp/key.json --iam-account team-a-dev@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
gcloud auth activate-service-account  --key-file=/tmp/key.json
gcloud container clusters get-credentials multi-tenant-cluster --zone us-central1-a --project ${GOOGLE_CLOUD_PROJECT}

# You'll see now that as team-a-dev you're able to list pods in the team-a namespace:
kubectl get pods --namespace=team-a

# But listing pods in the team-b namespace is restricted:
kubectl get pods --namespace=team-b

# Return to your first Cloud Shell tab or open a new one. Renew the cluster credentials and reset your context to the team-a namespace:
gcloud container clusters get-credentials multi-tenant-cluster --zone us-central1-a --project ${GOOGLE_CLOUD_PROJECT}
```

note: if want to revert to initial admin priviledges:
```
gcloud config set account student-00-de0c3e1cf8e7@qwiklabs.net
gcloud container clusters get-credentials multi-tenant-cluster --zone us-central1-a --project ${GOOGLE_CLOUD_PROJECT}
```

### 3. Resource Quotas
#### 3.1 Pods Quotas
For example, the following will set a limit to the number of pods allowed in the namespace "team-a" to 3, and the number of loadbalancers to 1:
```
kubectl create quota test-quota \
--hard=count/pods=2,count/services.loadbalancers=1 --namespace=team-a

# exstg running 1 pod, now try create a second pod & third pod to test the quota holds true
kubectl run app-server-2 --image=centos --namespace=team-a -- sleep infinity
kubectl run app-server-3 --image=centos --namespace=team-a -- sleep infinity	#action forbidden
kubectl describe quota test-quota --namespace=team-a
```

Update test-quota to have a limit of 6 pods by running:
```
export KUBE_EDITOR="nano"
kubectl edit quota test-quota --namespace=team-a

# edit modify count, save and exit
	count/pods: "6"

kubectl describe quota test-quota --namespace=team-a
```

#### 3.2 CPU & memory quotas
In this lab, your cluster has 4 n1-standard-1 machines, with 1 core and 3.75GB memory each. You have been provided with a sample resource quota yaml file for your cluster:
With this quota in place, the sum of all pods' CPU and memory requests will be capped at 2cpu and 8GiB, and their limits at 4cpu and 12GiB, respectively.
We create quotas using cpu-mem-quota.yaml file:
```
kubectl create -f cpu-mem-quota.yaml
kubectl describe quota cpu-mem-quota --namespace=team-a
```

Configure new pods using cpu-mem-demo-pod.yaml to see the resources being consumed
To demonstrate the CPU and memory quota, create a new pod using "cpu-mem-demo-pod.yaml":
```
kubectl create -f cpu-mem-demo-pod.yaml --namespace=team-a
kubectl describe quota cpu-mem-quota --namespace=team-a
kubectl describe quota -A
```

### 4. Monitoring GKE and GKE Usage Metering
Navigate around the console in GKE Dashboard.
Create Metrics with metrics explorer.

#### 4.1 GKE Usage metering
Allows you to export your GKE cluster resource utilization and consumption to a BigQuery dataset where you can visualize it using Data Studio.

Note: Because it c
an take several hours for GKE metric data to populate BigQuery, your lab project includes BigQuery datasets with simulated resource usage and billing data for demonstrative purposes.

The following two datasets have been added to your project:

cluster_dataset - this is a dataset manually created before enabling GKE usage metering on the cluster. This dataset contains 2 tables generated by GKE (gke_cluster_resource_consumption and gke_cluster_resource_usage) and is continuously updated with cluster usage metrics.

billing_dataset- this is a dataset manually created before enabling BigQuery export for billing. This dataset contains 1 table (gcp_billing_export_v1_xxxx) and is updated each day with daily costs of a project.

Enable GKE usage metering on the cluster and specify the dataset cluster_dataset:
```
gcloud container clusters \
update multi-tenant-cluster --zone us-central1-a --resource-usage-bigquery-dataset cluster_dataset
```

#### 4.2 Create the GKE cost breakdown table
Its a provided template to cleanup cluster dataset and exported into a separate table "cost_breakdown" table
SQL template provide "usage_metering_query_template.sql"

Set the path of the provided billing table, the provided usage metering dataset, and a name for the new cost breakdown table:
```
export GCP_BILLING_EXPORT_TABLE_FULL_PATH=${GOOGLE_CLOUD_PROJECT}.billing_dataset.gcp_billing_export_v1_xxxx
export USAGE_METERING_DATASET_ID=cluster_dataset
export COST_BREAKDOWN_TABLE_ID=usage_metering_cost_breakdown
```

Next, specify the path of the usage metering query template downloaded at the start of this lab, an output file for the usage metering query that will be generated, and a start date for the data (the earliest date in the data is 2020-10-26):
```
export USAGE_METERING_QUERY_TEMPLATE=~/gke-qwiklab/usage_metering_query_template.sql
export USAGE_METERING_QUERY=cost_breakdown_query.sql
export USAGE_METERING_START_DATE=2020-10-26

# generate the usage metering query:
sed \
-e "s/\${fullGCPBillingExportTableID}/$GCP_BILLING_EXPORT_TABLE_FULL_PATH/" \
-e "s/\${projectID}/$GOOGLE_CLOUD_PROJECT/" \
-e "s/\${datasetID}/$USAGE_METERING_DATASET_ID/" \
-e "s/\${startDate}/$USAGE_METERING_START_DATE/" \
"$USAGE_METERING_QUERY_TEMPLATE" \
> "$USAGE_METERING_QUERY"
```

Set up your cost breakdown table using the query you rendered in the previous step:
```
bq query \
--project_id=$GOOGLE_CLOUD_PROJECT \
--use_legacy_sql=false \
--destination_table=$USAGE_METERING_DATASET_ID.$COST_BREAKDOWN_TABLE_ID \
--schedule='every 24 hours' \
--display_name="GKE Usage Metering Cost Breakdown Scheduled Query" \
--replace=true \
"$(cat $USAGE_METERING_QUERY)"
```

Data Transfer should provide a link for authorization. Click it, log in with your student account, follow the instructions, and paste the version_info back in your Cloud Shell.

#### 4.3 Create the data source in Data Studio
[Data Studio Page](https://datastudio.google.com/u/0/navigation/datasources)

Follow steps to setup and start with Custom Query:
```
 SELECT *  FROM `[PROJECT-ID].cluster_dataset.usage_metering_cost_breakdown`
```
Follow illustrated steps to create data visual report

---
# END
---