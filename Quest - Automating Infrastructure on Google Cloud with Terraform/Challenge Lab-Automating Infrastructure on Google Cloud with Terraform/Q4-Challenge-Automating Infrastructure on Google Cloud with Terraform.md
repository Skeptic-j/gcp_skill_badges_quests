# Q4-Challenge Lab - Automating Infrastructure on Google Cloud with Terraform
[linkto challenge](https://www.cloudskillsboost.google/focuses/16502?parent=catalog)

## Summary of topics tested
- Import existing infrastructure into your Terraform configuration.

- Build and reference your own Terraform modules.

- Add a remote backend to your configuration.

- Use and implement a module from the Terraform Registry.

- Re-provision, destroy, and update infrastructure.

- Test connectivity between the resources you've created.

### 1.1 Create configuration files according to the following hierarchy structure
```
main.tf
variables.tf
modules/
└── instances
    ├── instances.tf
    ├── outputs.tf
    └── variables.tf
└── storage
    ├── storage.tf
    ├── outputs.tf
    └── variables.tf
```
Steps to create the respective directories and files
```
touch main.tf
touch variables.tf
mkdir modules
mkdir modules/instances
mkdir modules/storage
cd modules/instances
touch instances.tf
touch outputs.tf
cd ..
cd storage
touch storage.tf
touch outputs.tf
```

#### 1.2.1 add in variable into file ~/variables.tf
```
variable "project_id" {
  description = "The ID of the project to create the resource in."
  type        = string
  default	  = "qwiklabs-gcp-04-9723981765ac"
}
variable "region" {
  description = "The region of the project to create the resource in."
  type        = string
  default	  = "us-central1"
}
variable "zone" {
  description = "The zone of the project to create the resource in."
  type        = string
  default	  = "us-central1-a"
}
variable "network_name" {
  description = "The VPC name of the project to create the resource in."
  type        = string
}
```

Then make a copy of **variables.tf** file into subdirectory "instances" and "storage"
```
cp variables.tf modules/instances/variables.tf && cp variables.tf modules/storage/variables.tf
```

### 1.3 Writing the provider block into /main.tf
```
provider "google" {
  version = "~> 3.45.0"
  project     = var.project_id
  region      = var.region
  zone		  = var.zone
}
```
Then `terraform init`.

---
### 2.1 We want to import the two instances already created in the lab simulating existing resources to be imported to out terraform state
Add the code below into ~/main.tf
```
module "instances" {
  source = "./modules/instances"
  project_id = var.project_id
}
```
Run command `terraform init`!! Do not miss this step

### 2.2.2 write resource config block into modules/instances/instances.tf 
match the pre-existing instances config as accurate as possible for "tf-instance-1" "tf-instance-2".
In real world, all arguments should be provided but this lab requires the 5 key arguments ONLY as shown below
[manual](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)

```
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "n1-standard-1"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = "debian-10-buster-v20220118"
    }
  }
  network_interface {
    network = var.network_name
    access_config {}
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "n1-standard-1"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = "debian-10-buster-v20220118"
    }
  }
  network_interface {
    network = var.network_name
    access_config {}
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
```

#### 2.2.3 import infra state to module
There are 3 examples provided by the manual as follows, we'll use the third example
```
terraform import google_compute_instance.default {{project}}/{{zone}}/{{name}}		
terraform import google_compute_instance.default {{name}}							
terraform import module.instances.google_compute_instance.tf-instance-1 tf-instance-1 
# use this line above and repeat for tf-instance-2
terraform import module.instances.google_compute_instance.tf-instance-2 tf-instance-2

terraform show
terraform apply
```

---
### 3.1 Configure a remote backend
#### 3.1.1 add resource block into modules/storage/storage.tf
```
resource "google_storage_bucket" "remote-backend" {
  name          = "<REPLACE WITH LAB GIVEN BUCKET NAME>"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true
}
```

#### 3.1.2 add OPTIONAL output block to modules/storage/outputs.tf
```
output "bucket" {
  description = "The created storage bucket"
  value       = google_storage_bucket.remote-backend
}
```

### 3.2 add module block into /main.tf 
```
module "storage" {
  source = "./modules/storage"
  project_id = var.project_id
}
```
then `terraform init` and `terraform apply` to create bucket

### 3.3 add terraform block to /main.tf and migrate terraform state to the bucket
```
terraform {
  backend "gcs" {
    bucket  = "<REPLACE WITH GIVEN BUCKET NAME>"
    prefix  = "terraform/state"
  }
}
```
Then run command `terraform init -migrate-state` and `yes` to change tf state to GCS bucket.

---
### 4.1 modify resource on "tf-instance-1" at /modules/instances/instances.tf as follows:
```
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "n1-standard-2"
  ...
```
### 4.2 repeat steps above for "tf-instance-2"

### 4.3 add another new instance resources with instance name as given in the lab.
```
resource "google_compute_instance" "<REPLACE WITH LAB GIVEN NAME>" {
  name         = "<REPLACE WITH LAB GIVEN NAME>"
  machine_type = "n1-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = var.network_name
    }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
```

### 4.4 add outputs to /modules/instances/outputs.tf (OPTIONAL)
```
output "instance_name" {
  description = "The created storage bucket"
  value       = google_compute_instance.tf-instance-1.name
}
output "instance_network" {
  description = "The created storage bucket"
  value       = google_compute_instance.tf-instance-1.network_interface[0]
}
```
then `terraform apply`

---
### 5.1 Taint 3rd instance
```
terraform taint module.instances.google_compute_instance.<REPLACE WITH 3RD INSTANCE NAME>        
##forces to recreate the instance
terraform apply
```

### 5.2 remove the 3rd instance resource from /modules/instances/instances.tf
```
terraform apply          ##destroys the tainted VM
```

---
### 6.0 Use a module from the registry
Add "network" module from registry to /main.tf file.
[registry manual](https://registry.terraform.io/modules/terraform-google-modules/network/google/3.4.0)
```
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "3.4.0"
  # insert the 3 required variables here
  project_id = var.project_id
  network_name = "<REPLACE WITH GIVEN VPC NAME FROM THE LAB>"
  subnets = [
    {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "us-central1"
    },
	{
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "us-central1"
    }
  ]
  routing_mode = "GLOBAL"
}
```
Run `terraform init` command to install the module!

THen only we apply changes with `terraform apply`.

### 6.1 update subnet information in /modules/instances/instances.tf for tf-instance-1
[optional flags manual](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)

```
...
  network_interface {
	  network = var.network_name
    subnetwork = "subnet-01"
  }
```


### 6.2 repeat for tf-instance-2 use "subnet-02"
we apply changes with `terraform apply`.


---
### 7.1 add firewall resource to /main.tf
[firewall manual](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall#example-usage---firewall-basic)
```
resource "google_compute_firewall" "tf-firewall" {
  name    = "tf-firewall"
  network = "<REPLACE WITH LAB GIVEN VPC NAME>"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}
```

terraform apply

---
# END
---
