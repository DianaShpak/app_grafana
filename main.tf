############### Variables ###############

variable "hcloud_token" {
  default = "0QtyGLqWyuWkrPn49Pb5aO7aM80bqqJLusgEAErFpvWDMXcRHQgJEkfgWn3Un77r"
}

# Define provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

# Define Hetzner provider token
provider "hcloud" {
  token = var.hcloud_token
}

# Obtain ssh key data
data "hcloud_ssh_key" "ssh_key" {
  fingerprint = "c5:e7:80:f0:ed:07:3d:e3:97:19:fa:30:b0:7f:d5:e6"
}


resource "hcloud_server" "grafana" {
  count       = var.instances_grafana
  name        = "grafana-server-${count.index}"
  image       = var.os_type
  server_type = var.server_type
  location    = var.location
  ssh_keys  = ["${data.hcloud_ssh_key.ssh_key.id}"]
  labels = {
    type = "grafana"
  }
  user_data = file("user_data.yml")
}

resource "hcloud_server_network" "grafana_network" {
  count     = var.instances_grafana
  server_id = hcloud_server.grafana[count.index].id
  subnet_id = hcloud_network_subnet.hc_private_subnet_grafana.id
}

resource "hcloud_network_subnet" "hc_private_subnet_grafana" {
  network_id   = hcloud_network.hc_private_grafana.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.ip_range_grafana
}

resource "hcloud_network" "hc_private_grafana" {
  name     = "hc_private_grafana"
  ip_range = var.ip_range_grafana
}



output "grafana_servers_status" {
  value = {
    for server in hcloud_server.grafana :
    server.name => server.status
  }
}

output "grafana_servers_ips" {
  value = {
    for server in hcloud_server.grafana :
    server.name => server.ipv4_address
  }
}