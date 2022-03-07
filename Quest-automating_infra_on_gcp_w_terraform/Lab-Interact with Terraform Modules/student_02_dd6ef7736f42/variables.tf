variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
  default     = "qwiklabs-gcp-03-f1918e743466"
}
variable "name" {
  description = "Name of the buckets to create."
  type        = string
  default     = "qwiklabs-gcp-03-f1918e743466-bucket"
}