resource "oci_load_balancer_backend_set" "test_backend_set" {
  for_each = var.backend_sets
  dynamic "health_checker" {
    for_each = each.value.hc_protocol == "HTTP" ? [1] : []
    content {

      protocol = "HTTP"

      port                = lookup(each.value, "hc_port", null)
      interval_ms         = 10000
      response_body_regex = lookup(each.value, "hc_regex", ".*")
      return_code         = lookup(each.value, "hc_code", 200)

      url_path = lookup(each.value, "hc_url", "/")
    }
  }

  dynamic "health_checker" {
    for_each = each.value.hc_protocol == "TCP" ? [1] : []
    content {

      protocol = "TCP"
      port     = lookup(each.value, "hc_port", null)

    }
  }

  load_balancer_id = oci_load_balancer_load_balancer.app_load_balancer[each.value.lb].id
  name             = lookup(each.value, "name", "bkendset")
  policy           = lookup(each.value, "policy", "ROUND_ROBIN")


  dynamic "lb_cookie_session_persistence_configuration" {
    for_each = lookup(each.value, "lb_persistence", null) != null ? local.lb_persistence : {}
    content {


      #cookie_name        = 
      #disable_fallback   = var.backend_sets_cookie_session_persistence_configuration_disable_fallback
      #domain             = var.backend_sets_cookie_session_persistence_configuration_domain
      #is_http_only       = var.backend_sets_cookie_session_persistence_configuration_is_http_only
      is_secure = each.value.hc_protocol == "HTTP" ? false : true
      #max_age_in_seconds = var.backend_sets_cookie_session_persistence_configuration_max_age_in_seconds
      #path               = var.backend_sets_cookie_session_persistence_configuration_path
    }
  }

  dynamic "session_persistence_configuration" {
    for_each = lookup(each.value, "session_persistence", null) != null ? local.app_persistence : {}
    content {

      cookie_name = each.value.session_persistence

      #Optional
      #disable_fallback = var.backend_set_session_persistence_configuration_disable_fallback
    }
  }

  #   dynamic "ssl_configuration" {
  #     for_each = lookup(each.value, "ssl", null) != null ? var.backend_sets : {}
  #     content {


  #       certificate_name                  = oci_load_balancer_certificate.test_certificate.name
  #       cipher_suite_name                 = var.backend_set_ssl_configuration_cipher_suite_name
  #       protocols                         = ["TLSv1.2"]
  #       server_order_preference           = var.backend_set_ssl_configuration_server_order_preference
  #       trusted_certificate_authority_ids = var.backend_set_ssl_configuration_trusted_certificate_authority_ids
  #       verify_depth                      = var.backend_set_ssl_configuration_verify_depth
  #       verify_peer_certificate           = var.backend_set_ssl_configuration_verify_peer_certificate
  #     }
  #   }
}

locals {
  lb_persistence = { for k, v in var.backend_sets :
    k => {
      name             = k
      disable_fallback = false
    } if contains(keys(v), "lb_persistence")
  }
  app_persistence = { for k, v in var.backend_sets :
    k => {
      name             = k
      cookie_name      = v.cookie_name
      disable_fallback = false
    } if contains(keys(v), "app_persistence")
  }

}
