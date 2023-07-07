resource "kubernetes_ingress_v1" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "simple-fanout-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "kubernetes.io/ingress.class" =  "nginx"
    }
  }

  spec {
    ingress_class_name = "nginx"

    default_backend {
     
      service {
        name = "keycloak-server"
        port {
          number = 8080
        }
      }
    }     

    rule {
      host = "movie.greeta.net"

      http {

        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "keycloak-server"
              port {
                number = 8080
              }
            }
          }
        }

        path {
          path = "/oauth2"
          path_type = "Prefix"

          backend {
            service {
              name = "keycloak-server"
              port {
                number = 8080
              }
            }
          }

        }

        path {
          path = "/login"
          path_type = "Prefix"

          backend {
            service {
              name = "keycloak-server"
              port {
                number = 8080
              }
            }
          }

        }

        path {
          path = "/error"
          path_type = "Prefix"

          backend {
            service {
              name = "keycloak-server"
              port {
                number = 8080
              }
            }
          }

        }

        path {
          path = "/movie"
          path_type = "Prefix"

          backend {
            service {
              name = "movies-api"
              port {
                number = 8081
              }
            }
          }

        } 

        path {
          path = "/actuator/health"
          path_type = "Prefix"

          backend {
            service {
              name = "movies-api"
              port {
                number = 8081
              }
            }
          }

        }

        path {
          path = "/openapi"
          path_type = "Prefix"

          backend {
            service {
              name = "movies-api"
              port {
                number = 8081
              }
            }
          }

        }  

        path {
          path = "/webjars"
          path_type = "Prefix"

          backend {
            service {
              name = "movies-api"
              port {
                number = 8081
              }
            }
          }

        }                     



      }
    } 

    rule {
      host = "moviehub.greeta.net"
      http {

        path {
          backend {
            service {
              name = "movies-ui"
              port {
                number = 4200
              }
            }
          }

          path = "/"
          path_type = "Prefix"
        }
      }
    }      
    
  }
}
