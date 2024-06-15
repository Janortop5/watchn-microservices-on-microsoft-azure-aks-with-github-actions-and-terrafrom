resource "helm_release" "nginx_ingress_controller" {
  name       = "nginx-ingress-controller"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  version    = "7.6.0"  # Specify the version of the chart you want to use

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  provider = helm.aks
}
