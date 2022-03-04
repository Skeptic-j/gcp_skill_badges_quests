provider "google" {
  version = "~> 3.45.0"
  project     = var.project_id
  region      = var.region
  zone		  = var.zone
}
terraform {
  backend "gcs" {
    bucket  = "tf-bucket-275129"
    prefix  = "terraform/state"
  }
}
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "3.4.0"
  # insert the 3 required variables here
  project_id = var.project_id
  network_name = "tf-vpc-947846"
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
module "instances" {
  source = "./modules/instances"
  project_id = var.project_id
}
module "storage" {
  source = "./modules/storage"
  project_id = var.project_id
}
resource "google_compute_firewall" "tf-firewall" {
  name    = "tf-firewall"
  network = "tf-vpc-947846"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}