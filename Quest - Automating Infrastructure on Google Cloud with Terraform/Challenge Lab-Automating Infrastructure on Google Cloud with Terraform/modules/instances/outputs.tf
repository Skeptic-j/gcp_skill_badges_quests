output "instance_name" {
  description = "The created storage bucket"
  value       = google_compute_instance.tf-instance-1.name
}
output "instance_network" {
  description = "The created storage bucket"
  value       = google_compute_instance.tf-instance-1.network_interface[0]
}