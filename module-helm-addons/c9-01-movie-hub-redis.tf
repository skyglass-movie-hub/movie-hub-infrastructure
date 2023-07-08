resource "kubernetes_deployment_v1" "movie_hub_redis_deployment" {
  metadata {
    name = "movie-hub-redis"
    labels = {
      db = "movie-hub-redis"
    }
  }

  spec {
    selector {
      match_labels = {
        db = "movie-hub-redis"
      }
    }

    template {
      metadata {
        labels = {
          db = "movie-hub-redis"
        }
      }

      spec {
        container {
          name  = "movie-hub-redis"
          image = "redis:7.0"

          resources {
            requests = {
              cpu    = "100m"
              memory = "50Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "100Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "movie_hub_redis" {
  metadata {
    name = "movie-hub-redis"
    labels = {
      db = "movie-hub-redis"
    }
  }

  spec {
    selector = {
      db = "movie-hub-redis"
    }

    port {
      protocol = "TCP"
      port     = 6379
      target_port = 6379
    }
  }
}

# Resource: Polar Redis Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "movie_hub_redis_hpa" {
  metadata {
    name = "movie-hub-redis-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.movie_hub_redis_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 60
  }
}