resource "kubernetes_config_map_v1" "movies_config" {
  metadata {
    name      = "movies-config"
    labels = {
      app = "movies-api"
    }
  }

  data = {
    "movie-hub-api-prod.yml" = file("${path.module}/app-conf/movie-hub-api-prod.yml")
    "movie-hub-api.yml" = file("${path.module}/app-conf/movie-hub-api.yml")
  }
}


resource "kubernetes_deployment_v1" "movies_api_deployment" {
  depends_on = [kubernetes_deployment_v1.movies_mongodb_deployment]
  metadata {
    name = "movies-api"
    labels = {
      app = "movies-api"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "movies-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "movies-api"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8081"
        }        
      }
      spec {
        volume {
          name = "movies-config-volume"    
          config_map {
            name = "movies-config"
          }
        }
        
        container {
          image = "ghcr.io/skyglass-movie-hub/movie-hub-api"
          name  = "movies-api"
          image_pull_policy = "Always"
          port {
            container_port = 8081
          }
          env {
            name  = "SPRING_CONFIG_LOCATION"
            value = "file:/config-repo/movie-hub-api.yml,file:/config-repo/movie-hub-api-prod.yml"
          }

          env {
            name = "SPRING_DATA_MONGODB_URI"
            value = "mongodb://movies-mongodb:27017/moviesdb"
          }  
          env {
            name = "SPRING_KEYCLOAK_SERVER_URL"
            value = "http://keycloak-server:8080"
          }   
          env {
            name = "MOVIES_APP_BASE_URL"
            value = "https://movie.greeta.net"
          }

          volume_mount {
            name       = "movies-config-volume"
            mount_path = "/config-repo"
          }


        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "movies_api_hpa" {
  metadata {
    name = "movies-api-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.movies_api_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "movies_api_service" {
  metadata {
    name = "movies-api"
  }
  spec {
    selector = {
      app = "movies-api"
    }
    port {
      port = 8081
    }
  }
}
