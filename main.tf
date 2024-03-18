# Define variables
variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "regions" {
  description = "List of regions for subnets"
  type        = list(string)
}

variable "workload_pool" {
  description = "workload pool"
}

# Create VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "my-vpc-network"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Create private subnet
resource "google_compute_subnetwork" "private_subnet" {
  count         = length(var.regions)
  name          = "private-subnet-${count.index}"
  ip_cidr_range = "10.${count.index}.0.0/16"
  region        = var.regions[count.index]
  network       = google_compute_network.vpc_network.self_link
  project       = var.project_id
}

# Create public subnet
resource "google_compute_subnetwork" "public_subnet" {
  count         = length(var.regions)
  name          = "public-subnet-${count.index}"
  ip_cidr_range = "10.${count.index}.1.0/24"
  region        = var.regions[count.index]
  network       = google_compute_network.vpc_network.self_link
  project       = var.project_id
}

# Create Autopilot cluster within private subnet
resource "google_container_cluster" "private_cluster" {
  name       = "private-cluster"
  project    = var.project_id
  location   = var.region
  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.private_subnet[0].self_link # Assuming one region for simplicity
  release_channel {
    channel = "REGULAR"
  }

  node_pool {
    name = "default-node-pool"

    # Define the Autopilot configuration
    node_config {
      preemptible  = false
      machine_type = "e2-medium"
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    }

    autoscaling {
      min_node_count = 4
      max_node_count = 6
    }
  }

  workload_identity_config {
    workload_pool = var.workload_pool
  }

  # Disable deletion protection
  deletion_protection = false
}

# Create Autopilot cluster within public subnet
resource "google_container_cluster" "public_cluster" {
  name       = "public-cluster"
  project    = var.project_id
  location   = var.region
  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.public_subnet[0].self_link # Assuming one region for simplicity
  release_channel {
    channel = "REGULAR"
  }

  node_pool {
    name = "default-node-pool"

    # Define the Autopilot configuration
    node_config {
      preemptible  = false
      machine_type = "e2-medium"
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    }

    autoscaling {
      min_node_count = 4
      max_node_count = 6
    }
  }

  workload_identity_config {
    workload_pool = var.workload_pool
  }

  # Disable deletion protection
  deletion_protection = false
}
