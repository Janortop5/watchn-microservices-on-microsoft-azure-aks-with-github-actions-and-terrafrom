# Create a DNS zone in Azure
resource "azurerm_dns_zone" "dns_zone" {
  name                = var.domain.domain
  resource_group_name = azurerm_resource_group.rg.name
}

data "kubernetes_service" "ingress_service" {
  metadata {
    name = "nginx-ingress-controller"
  }

  depends_on = [
     helm_release.nginx_ingress_controller
  ]

  provider = kubernetes.aks
}

# Create a CNAME record in the Azure DNS zone
resource "azurerm_dns_cname_record" "dns_record" {
  name                = var.domain.record
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  record              = data.kubernetes_service.ingress_service.status.0.load_balancer.0.ingress.0.ip
}

locals {
  dns_name_servers = tolist(azurerm_dns_zone.dns_zone.name_servers)
}

resource "namedotcom_domain_nameservers" "eaaladejana_xyz" {
  domain_name = "eaaladejana.xyz"
  nameservers = [
    "${substr(local.dns_name_servers[0], 0, length(local.dns_name_servers[0]) - 1)}",
    "${substr(local.dns_name_servers[1], 0, length(local.dns_name_servers[1]) - 1)}",
    "${substr(local.dns_name_servers[2], 0, length(local.dns_name_servers[2]) - 1)}",
    "${substr(local.dns_name_servers[3], 0, length(local.dns_name_servers[3]) - 1)}",
  ]
}

