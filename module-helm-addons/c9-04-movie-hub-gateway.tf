resource "kubernetes_config_map_v1" "movie_hub_gateway_config" {
  metadata {
    name      = "movie-hub-gateway-config"
    labels = {
      app = "movie-hub-gateway"
    }
  }

  data = {
    "application.yml" = file("${path.module}/app-conf/movie-hub-gateway.yml")
    "application-prod.yml" = file("${path.module}/app-conf/movie-hub-gateway-prod.yml")
  }

}


resource "kubernetes_deployment_v1" "movie_hub_gateway_deployment" {
  depends_on = [kubernetes_deployment_v1.polar_postgres_deployment,
        kubernetes_deployment_v1.polar_rabbitmq_deployment,
        kubernetes_deployment_v1.polar_redis_deployment]
  metadata {
    name = "movie-hub-gateway"
    labels = {
      app = "movie-hub-gateway"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "movie-hub-gateway"
      }
    }

    template {
      metadata {
        labels = {
          app = "movie-hub-gateway"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "9000"
        }
      }

      spec {
        container {
          name  = "movie-hub-gateway"
          image = "ghcr.io/skyglass-books/movie-hub-gateway"
          image_pull_policy = "Always"

          lifecycle {
            pre_stop {
              exec {
                command = ["sh", "-c", "sleep 5"]
              }
            }
          }

          resources {
            requests = {
              memory = "756Mi"
              cpu    = "0.1"
            }
            limits = {
              memory = "756Mi"
              cpu    = "2"
            }
          }          

          port {
            container_port = 9000
          }

          env {
            name  = "SPRING_PROFILES_ACTIVE"
            value = "prod"
          }          

          env {
            name  = "MOVIES_API_URL"
            value = "http://movies-api:8081"
          }

          env {
            name  = "SPA_URL"
            value = "http://movies-ui:4200"
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 9000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 9000
            }
            initial_delay_seconds = 5
            period_seconds        = 15
          }

          volume_mount {
            name      = "movie-hub-gateway-config-volume"
            mount_path = "/workspace/config"
          }

          volume_mount {
            name      = "redis-credentials-volume"
            mount_path = "/workspace/secrets/redis"
          }
          volume_mount {
            name      = "keycloak-client-credentials-volume"
            mount_path = "/workspace/secrets/keycloak-client"
          }
          volume_mount {
            name      = "keycloak-issuer-secret-volume"
            mount_path = "/workspace/secrets/keycloak-issuer"
          }

        }

        volume {
          name = "movie-hub-gateway-config-volume"
          config_map {
            name = "movie-hub-gateway-config"
          }
        }

        volume {
          name = "redis-credentials-volume"
          secret {
            secret_name = "polar-redis-credentials"
          }
        }
        volume {
          name = "keycloak-client-credentials-volume"
          secret {
            secret_name = "keycloak-server-client-credentials"
          }
        }
        volume {
          name = "keycloak-issuer-secret-volume"
          secret {
            secret_name = "keycloak-issuer-secret"
          }
        }        
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "movie_hub_gateway_hpa" {
  metadata {
    name = "movie-hub-gateway-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.movie_hub_gateway_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 80
  }
}

resource "kubernetes_service_v1" "movie_hub_gateway_service" {
  metadata {
    name = "movie-hub-gateway"
  }
  spec {
    selector = {
      app = "movie-hub-gateway"
    }
    port {
      port = 9000
    }
  }
}
