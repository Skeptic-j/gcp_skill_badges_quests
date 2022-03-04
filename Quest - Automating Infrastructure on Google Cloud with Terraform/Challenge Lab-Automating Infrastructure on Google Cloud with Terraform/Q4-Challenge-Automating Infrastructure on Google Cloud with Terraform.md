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
touch variable.tf
mkdir modules
mkdir modules/instances
mkdir modules/storage
cd modules/instances
touch instances.tf
touch outputs.tf
cd modules/storage
touch storage.tf
touch outputs.tf
```

#### 1.2.1 add in variable into file /variables.tf
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
```

#### 1.2.2 Make a copy of variables file in sub directory
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

### 1.4 terraform init

---
### 2.1 We want to import Two instances already created in the lab simulating existing resources
#### 2.2.1 add into /main.tf
```
module "instances" {
  source = "./modules/instances"
  project_id = var.project_id
}
```
terraform init

### 2.2.2 write resource config block into modules/instances/instances.tf 
(match the pre-existing instances)("tf-instance-1" "tf-instance-2")
this lab requires the 5 key arguments ONLY as shown below
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
    network = "default"
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
    network = "default"
    access_config {}
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
```

#### 2.2.3 import infra state to module
```
terraform import google_compute_instance.default {{project}}/{{zone}}/{{name}}		#provided in manual but not used
terraform import google_compute_instance.default {{name}}							#provided in manual but not used
terraform import module.instances.google_compute_instance.tf-instance-1 tf-instance-1 
# use this line above and repeat for tf-instance-2

terraform show
terraform apply
```

---
### 3.1 Configure a remote backend
#### 3.1.1 add resource block into modules/storage/storage.tf
```
resource "google_storage_bucket" "remote-backend" {
  name          = "USE LAB GIVEN BUCKET NAME"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true
}
```

#### 3.1.2 add OPTIONAL output block to modules/storage/outputs.tf
```
output "bucket" {
  description = "The created storage bucket"
  value       = google_storage_bucket.static-site
}
```

### 3.2 add module block into /main.tf 
```
module "storage" {
  source = "./modules/storage"
  project_id = var.project_id
}
```
then terraform init and apply to create bucket

### 3.3 add terraform block to /main.tf 
```
terraform {
  backend "gcs" {
    bucket  = "PARSE GIVEN BUCKET NAME"
    prefix  = "terraform/state"
  }
}
```
### 3.4 terraform init -migrate-state and yes to change tf state to GCS bucket

---
### 4.1 modify resource on "tf-instance-1" at /modules/instances/instances.tf
```
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "n1-standard-2"
  ...
```
### 4.2 repeat steps above for "tf-instance-2"

### 4.3 add another new instance resources with name = <FOLLOW LAB GIVEN NAME>
```
resource "google_compute_instance" "<FOLLOW LAB GIVEN NAME>" {
  name         = "<FOLLOW LAB GIVEN NAME>"
  machine_type = "n1-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = "default"
    }
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
terraform apply

---
### 5.1 Taint 3rd instance
```
terraform taint module.instances.google_compute_instance.tf-instance-342178        ##force to recreate the instance
terraform apply
```

### 5.2 remove the 3rd instance resource from /modules/instances/instances.tf
```
terraform apply          ##destroys the tainted VM
```

---
### 6.0 Use a module from the registry
### 6.2 Add "network" module from registry to /main.tf file
[registry manual](https://registry.terraform.io/modules/terraform-google-modules/network/google/3.4.0)
```
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "3.4.0"
  # insert the 3 required variables here
  project_id = var.project_id
  network_name = "<USE GIVEN VPC NAME FROM THE LAB>"
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

### 6.3 terraform apply

### 6.4 update subnet information in /modules/instances/instances.tf for tf-instance-1
[optional flags manual](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)
```
...
  network_interface {
	network = "USE VPC NAME GIVEN IN THE LAB"
    subnetwork = "subnet-01"
    }
  }
```

### 6.5 repeat for tf-instance-2 use "subnet-02"

terraform apply (might need to init if error)

---
### 7.1 add firewall resource to /main.tf
[firewall manual](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall#example-usage---firewall-basic)
```
resource "google_compute_firewall" "tf-firewall" {
  name    = "tf-firewall"
  network = "USE LAB GIVEN VPC NAME"

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
