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