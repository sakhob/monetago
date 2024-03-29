variable "gke_username" {
  default = ""
  description = "GKE Username"
}

variable "gke_password" {
  default = ""
  description = "GKE Password"
}

variable "gke_num_nodes" {
  default = 2
  description = "Number of GKE nodes"
}

data "google_client_config" "default" {}

resource "google_container_cluster" "primary" {
  provider = "google-beta"
  name = "${var.project_id}-gke"
  location = var.region

  remove_default_node_pool = true
  initial_node_count = 1
  enable_shielded_nodes = true

  network = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  addons_config {
    istio_config {
      disabled = false
    }
  }
}


resource "google_container_node_pool" "primary_nodes" {
  name = "${google_container_cluster.primary.name}-node-pool"
  location = var.region
  cluster = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  autoscaling {
    max_node_count = 4
    min_node_count = 1
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]

    labels = {
      env = var.project_id
    }

    machine_type = "n1-standard-1"
    tags = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

