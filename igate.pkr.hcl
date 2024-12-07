packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.4"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

variable "digitalocean_token" {
  type        = string
  description = "the token to use when using the digitalocean builder"
  sensitive   = true
}

variable "dashboard_domain" {
  type        = string
  description = "the FQDN for the grafana dashboard"
  sensitive   = false
  default     = "dashboard.k7bcx.com"
}

variable "metrics_domain" {
  type        = string
  description = "the FQDN for the metrics domain"
  sensitive   = false
  default     = "metrics.k7bcx.com"
}

variable "logs_domain" {
  type        = string
  description = "the FQDN for the logs domain"
  sensitive   = false
  default     = "logs.k7bcx.com"
}

variable "grafana_admin_password" {
  type        = string
  description = "the admin password for grafana"
  sensitive   = true
}

variable "grafana_secret_key" {
  type        = string
  description = "secret key for signing data source settings in grafana"
  sensitive   = true
}

variable "telegraf_token" {
  type        = string
  description = "token for telegraf authentication"
  sensitive   = true
}

variable "call" {
  type        = string
  description = "the call sign of the igate"
  sensitive   = false
  default     = "K7BCX-10"
}

variable "fluent_shared_key" {
  type        = string
  description = "shared key for fluentbit authentication"
  sensitive   = true
}

source "digitalocean" "igate-dashboard" {
  api_token     = var.digitalocean_token
  image         = "ubuntu-22-04-x64"
  size          = "s-1vcpu-1gb"
  region        = "sfo3"
  snapshot_name = "igate-dashboard-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  communicator              = "ssh"
  ssh_username              = "root"
  ssh_clear_authorized_keys = true
}

build {
  sources = [
    "source.digitalocean.igate-dashboard"
  ]

  provisioner "shell" {
    script = "packages.sh"
  }

  provisioner "shell" {
    inline = [
      "mkdir -v /etc/frontail",
      "mkdir -v /var/log/direwolf",
    ]
  }

  provisioner "shell" {
    inline = [
      "mkdir /etc/fluent-bit/conf.d"
    ]
  }

  provisioner "file" {
    sources = [
      "fluent/fluent-bit.conf"
    ]
    destination = "/etc/fluent-bit/fluent-bit.conf"
  }
  provisioner "shell" {
    inline = [
      "printf \"@SET call=%s\\n\" \"${var.call}\" >> /etc/fluent-bit/fluent-bit.conf",
      "sed -i -e '/@SET call/ s/-/_/' /etc/fluent-bit/fluent-bit.conf"
    ]
  }

  provisioner "file" {
    sources = [
      "fluent/input.conf",
      "fluent/filter.conf",
      "fluent/output.conf"
    ]
    destination = "/etc/fluent-bit/conf.d/"
  }

  provisioner "file" {
    source      = "frontail/frontail.json"
    destination = "/etc/frontail/direwolf.json"
  }

  provisioner "file" {
    sources = [
      "frontail/frontail.service"
    ]
    destination = "/etc/systemd/system/"
  }

  provisioner "shell" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable frontail"
    ]
  }

  provisioner "file" {
    sources = [
      "victoria-metrics/victoria-metrics.service"
    ]
    destination = "/etc/systemd/system/victoria-metrics.service"
  }

  provisioner "shell" {
    scripts = [
      "victoria-metrics/configure-victoria-metrics.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable victoria-metrics"
    ]
  }

  provisioner "file" {
    sources = [
      "victoria-logs/victoria-logs.service"
    ]
    destination = "/etc/systemd/system/victoria-logs.service"
  }

  provisioner "shell" {
    scripts = [
      "victoria-logs/configure-victoria-logs.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable victoria-logs"
    ]
  }

  provisioner "file" {
    source      = "telegraf/direwolf.conf"
    destination = "/etc/telegraf/telegraf.d/"
  }

  provisioner "shell" {
    scripts = [
      "telegraf/configure-telegraf.sh"
    ]
    environment_vars = [
      "ORG=${var.call}",
      "INFLUX_PROXY_TOKEN=${var.telegraf_token}",
      "TELEGRAF_HOST=${var.metrics_domain}"
    ]
  }

  provisioner "shell" {
    scripts = [
      "grafana/configure-grafana.sh"
    ]
    environment_vars = [
      "CALL=${var.call}",
      "DOMAIN=${var.dashboard_domain}",
      "ADMIN_PASSWORD=${var.grafana_admin_password}",
      "SECRET_KEY=${var.grafana_secret_key}"
    ]
  }

  provisioner "file" {
    sources = [
      "grafana/datasources/telegraf.yaml"
    ]
    destination = "/etc/grafana/provisioning/datasources/"
  }

  provisioner "file" {
    sources = [
      "grafana/dashboards/provision.yaml"
    ]
    destination = "/etc/grafana/provisioning/dashboards/"
  }

  provisioner "file" {
    sources = [
      "grafana/dashboards/igate.json"
    ]
    destination = "/var/lib/grafana/dashboards/"
  }

  provisioner "file" {
    source      = "caddy/Caddyfile"
    destination = "/etc/caddy/Caddyfile"
  }

  provisioner "shell" {
    script = "caddy/configure-caddy.sh"
    environment_vars = [
      "LOGS_DOMAIN=${var.logs_domain}",
      "DASHBOARD_DOMAIN=${var.dashboard_domain}",
      "METRICS_DOMAIN=${var.metrics_domain}",
      "LOGS_TOKEN=${var.fluent_shared_key}",
      "METRICS_TOKEN=${var.telegraf_token}",
      "GRAFANA_ADMIN_PASSWORD=xxxxxx"
    ]
  }

  provisioner "shell" {
    inline = [
      "printf \"ADMIN_HASH=%s\\n\" \"$(caddy hash-password --plaintext '${var.grafana_admin_password}')\" > /tmp/caddy-validate.env",
      "caddy validate --envfile /tmp/caddy-validate.env --config /etc/caddy/Caddyfile",
      "rm /tmp/caddy-validate.env"
    ]
    environment_vars = [
      "LOGS_DOMAIN=${var.logs_domain}",
      "DASHBOARD_DOMAIN=${var.dashboard_domain}",
      "METRICS_DOMAIN=${var.metrics_domain}",
      "LOGS_TOKEN=${var.fluent_shared_key}",
      "METRICS_TOKEN=${var.telegraf_token}"
    ]
  }


  provisioner "shell" {
    script = "sysprep.sh"
  }
}

# vi: et ts=2 sw=2
