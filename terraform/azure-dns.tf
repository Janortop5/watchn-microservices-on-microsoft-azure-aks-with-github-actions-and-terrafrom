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

resource "namedotcom_domain_nameservers" "eaaladejana_xyz" {
  domain_name = eaaladejana.xyz
  nameservers = [
    "azurerm_dns_zone.dns_zone.name_servers[0]",
    "azurerm_dns_zone.dns_zone.name_servers[1]",
    "azurerm_dns_zone.dns_zone.name_servers[2]",
    "azurerm_dns_zone.dns_zone.name_servers[3]",
  ]
}
