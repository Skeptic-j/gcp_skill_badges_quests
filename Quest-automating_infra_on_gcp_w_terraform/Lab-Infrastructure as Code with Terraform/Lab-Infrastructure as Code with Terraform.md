# Q4 - Infrastructure as Code with Terraform
This lab is guided and full instructions can be found in the following [linktolab](https://www.cloudskillsboost.google/focuses/15842?parent=catalog)<br>
This documentation is an interpreted shortened version of my own attempt at this setup.

## Objectives of the guided lab
* Build, change, and destroy infrastructure with Terraform

* Create Resource Dependencies with Terraform

* Provision infrastructure with Terraform 
---
## The Basic commands
```
terraform init
terraform plan
terraform plan -destroy
terraform destroy
terraform apply
terraform show
terraform output
```

Saving a plan for future application:
```
terraform plan -out name_of_plan
terraform apply "name_of_plan"
```
---
## Force recreation of a resource, in this example "google_compute_instance.vm_instance"
```
terraform taint google_compute_instance.vm_instance
terraform apply
```
---
## Creating the `main.tf` file with respective code blocks
```
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

# provider block
provider "google" {
  project = "qwiklabs-gcp-01-eb78518c7a43"
  region  = "us-central1"
  zone    = "us-central1-c"
}

# create network
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
```
---
## Provision Infrastructure
Create instance with provisioner. TF uses provisioners to upload files, run shell scripts, or install and trigger other software like configuration management tools.
Further read: https://www.terraform.io/language/resources/provisioners/local-exec
```
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags         = ["web", "dev"]
  provisioner "local-exec" {
    command = "echo ${google_compute_instance.vm_instance.name}:  ${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip} >> ip_address.txt"
  }  
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}

#create static IP
resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}

# New resource for the storage bucket our application will use.
resource "google_storage_bucket" "example_bucket" {
  name     = "qwiklabs-gcp-01-eb78518c7a43-bucket"
  location = "US"
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}
```
---
## Create a new instance that uses the bucket with explicit dependency specified
```
resource "google_compute_instance" "another_instance" {
  # Tells Terraform that this VM instance must be created only after the
  # storage bucket has been created.
  depends_on = [google_storage_bucket.example_bucket]
  name         = "terraform-instance-2"
  machine_type = "f1-micro" 
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}

# create an output after  "terraform apply"
output "another_vm_instance_ip"{
    description = "IP of another_instance"
    value = google_compute_instance.another_instance.network_interface[0].access_config[0]
}
```
---
## END
---

