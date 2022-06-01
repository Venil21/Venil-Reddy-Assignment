provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

locals {
    app_data = jsondecode(file("/Users/venilreddy/Documents/GitHub/VenilReddy-Assignment/application.json"))
}


resource "kubernetes_deployment" "app"  {
  count = length(local.app_data.applications)
  metadata {
    name = local.app_data.applications[count.index].name
    labels = {
      App = local.app_data.applications[count.index].name
    }
  }

  spec {
    replicas = local.app_data.applications[count.index].replicas

    selector {
      match_labels = {
        App = local.app_data.applications[count.index].name
      }
    }

    template {
      metadata {
        labels = {
          App = local.app_data.applications[count.index].name
        }
      }

      spec {
        container {
          image = "hashicorp/http-echo"
          name  = local.app_data.applications[count.index].name
          args  = ["-listen",":${local.app_data.applications[count.index].port}","-text","I am ${local.app_data.applications[count.index].name}"]
          port {
            container_port = local.app_data.applications[count.index].port
          } 
          }

        }
      }
    }
  }

  resource "kubernetes_service" "service" {
    count = length(local.app_data.applications)
    metadata {
    name = local.app_data.applications[count.index].name
  }
    spec{
      type = "NodePort"
      selector = {
        App = local.app_data.applications[count.index].name
      }
      port {
            port = local.app_data.applications[count.index].port
            target_port = local.app_data.applications[count.index].port
          } 
    }
  }

 resource "kubernetes_ingress_v1" "ingress" {
  count = length(local.app_data.applications)
  metadata {
    name = local.app_data.applications[count.index].name
    annotations = {
      "nginx.ingress.kubernetes.io/canary" = "true"
      "nginx.ingress.kubernetes.io/canary-weight" = "${local.app_data.applications[count.index].traffic_weight}"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          backend {
            service{
              name = local.app_data.applications[count.index].name
              port {
               number = local.app_data.applications[count.index].port
              }
            }
          }
          path = "/"
        }
      }
    }
  }
}