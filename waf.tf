resource "oci_waf_web_app_firewall_policy" "waf_policy" {
  actions {

    name = "Pre-configured Check Action"
    type = "CHECK"
  }
  actions {

    name = "Pre-configured Allow Action"
    type = "ALLOW"
  }
  actions {
    body {
      text = "{\"code\":\"401\",\"message\":\"Unauthorized\"}"
      type = "STATIC_TEXT"
    }
    code = "401"
    headers {
      name  = "Content-Type"
      value = "application/json"
    }
    name = "Pre-configured 401 Response Code Action"
    type = "RETURN_HTTP_RESPONSE"
  }
  compartment_id = var.compartment_id

  display_name = var.waf_policy_display_name

  request_protection {

    body_inspection_size_limit_in_bytes = "8192"
    rules {
      action_name = "Pre-configured 401 Response Code Action"

      condition_language         = "JMESPATH"
      is_body_inspection_enabled = "false"
      name                       = "recommendedprotection"
      protection_capabilities {

        key     = "9420000"
        version = "2"
      }
      protection_capabilities {

        key     = "941140"
        version = "2"
      }
      protection_capabilities {

        key     = "9410000"
        version = "3"
      }
      protection_capabilities {

        key     = "9330000"
        version = "2"
      }
      protection_capabilities {

        key     = "9320001"
        version = "2"
      }
      protection_capabilities {

        key     = "9320000"
        version = "2"
      }
      protection_capabilities {

        key     = "930120"
        version = "2"
      }
      protection_capabilities {

        key     = "9300000"
        version = "2"
      }
      protection_capabilities {

        key     = "920390"
        version = "1"
      }
      protection_capabilities {

        key     = "920380"
        version = "1"
      }
      protection_capabilities {

        key     = "920370"
        version = "1"
      }
      protection_capabilities {

        key     = "920320"
        version = "1"
      }
      protection_capabilities {

        key     = "920300"
        version = "1"
      }
      protection_capabilities {

        key     = "911100"
        version = "1"
      }

      type = "PROTECTION"
    }
  }

}

resource "oci_waf_web_app_firewall" "waf_web_app_firewall" {
  for_each = var.lb_options

  compartment_id             = var.compartment_id
  backend_type               = "LOAD_BALANCER"
  load_balancer_id           = oci_load_balancer_load_balancer.app_load_balancer[each.key].id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.waf_policy.id

  display_name = var.waf_web_app_firewall

}
