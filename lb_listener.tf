resource "oci_load_balancer_listener" "lb_listener" {

  for_each = var.listeners

  default_backend_set_name = oci_load_balancer_backend_set.test_backend_set[each.value.bkend].name
  load_balancer_id         = oci_load_balancer_load_balancer.app_load_balancer[each.value.lb].id
  name                     = each.value.name
  port                     = lookup(each.value, "port", 80)
  protocol                 = lookup(each.value, "protocol", "HTTP")


  dynamic "connection_configuration" {
    for_each = each.value.protocol == "TCP" ? var.listeners : {}
    content {
      idle_timeout_in_seconds = lookup(each.value, "timeout", 300)
    }
  }
  hostname_names = lookup(each.value, "protocol", null) != "TCP" ? [for i in each.value.hostnames : format("%s_%s", each.key, i) if length(i) > 0] : null

  dynamic "ssl_configuration" {
    iterator = ssl
    for_each = length(var.cert_lb) > 0 && each.value.port == 443 ? var.cert_lb : {}
    content {

      certificate_name = oci_load_balancer_certificate.test_certificate[ssl.key].certificate_name

      verify_depth            = lookup(each.value, "verify_depth", 3)
      verify_peer_certificate = lookup(each.value, "verify_peer_certificate", false)
    }
  }
}

