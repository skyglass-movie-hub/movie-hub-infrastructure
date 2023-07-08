resource "kubernetes_secret_v1" "movie_hub_redis_credentials" {
  metadata {
    name = "movie-hub-redis-credentials"
  }

  data = {
    "spring.redis.host"     = "movie-hub-redis"
    "spring.redis.port"     = "6379"
    "spring.redis.username" = "default"
  }
}

resource "kubernetes_secret_v1" "movie_hub_keycloak_client_credentials" {
  metadata {
    name = "keycloak-server-client-credentials"
  }

  data = {
    "spring.security.oauth2.client.registration.keycloak.client-secret" = "1b1b19599c2264fd218c"
  }
}

resource "kubernetes_secret_v1" "keycloak_issuer_secret" {
  metadata {
    name = "keycloak-issuer-secret"
  }

  data = {
    "spring.keycloak.server-url" = "http://keycloak-server:8080"
  }
}