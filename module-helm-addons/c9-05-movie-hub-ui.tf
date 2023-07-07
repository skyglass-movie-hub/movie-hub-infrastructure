resource "kubernetes_deployment_v1" "movies_ui_deployment" {
  depends_on = [kubernetes_deployment_v1.movies_api_deployment]
  metadata {
    name = "movies-ui"
    labels = {
      app = "movies-ui"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "movies-ui"
      }
    }
    template {
      metadata {
        labels = {
          app = "movies-ui"
        }
      }
      spec {
        container {
          image = "ghcr.io/skyglass-movie-hub/movie-hub-ui"
          name  = "movies-ui"
          image_pull_policy = "Always"
          port {
            container_port = 4200
          }                                                                                          
        }
      }
    }
  }
}

# Resource: Keycloak Server Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "movies_ui_hpa" {
  metadata {
    name = "movies-ui-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.movies_ui_deployment.metadata[0].name
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "movies_ui_service" {
  metadata {
    name = "movies-ui"
  }
  spec {
    selector = {
      app = "movies-ui"
    }
    port {
      port = 4200
    }
  }
}
