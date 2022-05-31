module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.4.0"

  compartment_id          = var.compartment_id
  region                  = var.region
  create_internet_gateway = true
  vcn_cidrs               = var.vcn_cidrs

}
locals {
  dhcp_default_options = data.oci_core_dhcp_options.dhcp_options.options.0.id
}

resource "oci_core_subnet" "vcn_subnet" {
  for_each       = length(var.subnets) > 0 ? var.subnets : {}
  cidr_block     = each.value.cidr_block
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id


  dhcp_options_id = local.dhcp_default_options
  display_name    = lookup(each.value, "name", each.key)
  dns_label       = lookup(each.value, "dns_label", null)
  freeform_tags   = lookup(each.value, "tags", null)

  prohibit_public_ip_on_vnic = lookup(each.value, "type", "public") == "public" ? false : true
  route_table_id             = lookup(each.value, "type", "public") == "public" ? module.vcn.ig_route_id : module.vcn.nat_route_id
  security_list_ids          = null
}

data "oci_core_dhcp_options" "dhcp_options" {

  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
}

resource "oci_load_balancer_load_balancer" "app_load_balancer" {
  for_each = var.lb_options

  compartment_id = var.compartment_id
  display_name   = var.prefix != "none" ? format("%s-%s", var.prefix, lookup(each.value, "name", "lb")) : lookup(each.value, "name", "lb")
  shape          = "flexible"
  subnet_ids     = [for v in oci_core_subnet.vcn_subnet : v.id]


  freeform_tags              = lookup(each.value, "tags", null)
  ip_mode                    = lookup(each.value, "ip_mode", "IPV4")
  is_private                 = lookup(each.value, "private", false)
  network_security_group_ids = [oci_core_network_security_group.public_lb_nsg.id]

  dynamic "reserved_ips" {
    for_each = lookup(each.value, "reserved_ip", null) != null ? [oci_core_public_ip.reserved_ip[each.key].id] : []
    content {

      id = reserved_ips.value
    }
  }
  shape_details {
    maximum_bandwidth_in_mbps = lookup(each.value, "max", 10)
    minimum_bandwidth_in_mbps = lookup(each.value, "min", 10)
  }
}

locals {
  reserved_ip = { for k, v in var.lb_options : k => v if lookup(v, "reserved_ip", false) == true }

}
resource "oci_core_public_ip" "reserved_ip" {
  for_each = local.reserved_ip

  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = format("%s-%s", lookup(each.value, "name", each.key), "reserved_ip")
  lifecycle {
    ignore_changes = [private_ip_id]
  }

}
resource "oci_load_balancer_hostname" "lb_hostname" {
  #Required
  for_each         = length(local.hostnames) > 0 ? { for v in local.hostnames : v.name => v } : {}
  hostname         = each.value.hostname
  load_balancer_id = oci_load_balancer_load_balancer.app_load_balancer[each.value.lb].id
  name             = each.key
}

locals {
  hostnames = flatten([for k, v in var.listeners : (lookup(v, "hostnames", null) != null ? [for v2 in v.hostnames : { lb = v.lb, listener_name = k, hostname = v2, name = "${k}_${v2}" }] : [])])
}


resource "oci_core_network_security_group" "public_lb_nsg" {

  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "Public_lb"

}

resource "oci_core_network_security_group_security_rule" "allow_http_from_all" {
  for_each                  = var.listeners
  network_security_group_id = oci_core_network_security_group.public_lb_nsg.id
  direction                 = "INGRESS"
  protocol                  = 6 # tcp

  description = "Allow port ${lookup(each.value, "port", 80)} from all"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    destination_port_range {

      min = lookup(each.value, "port", 80)
      max = lookup(each.value, "port", 80)
    }

  }

}


#LB Certificate
resource "oci_load_balancer_certificate" "test_certificate" {

  for_each         = length(var.cert_lb) > 0 ? var.cert_lb : {}
  certificate_name = format("%s-%s", each.key, "cert")
  load_balancer_id = oci_load_balancer_load_balancer.app_load_balancer[each.key].id

  ca_certificate     = lookup(each.value, "ca_certificate", null) != null ? file(each.value.ca_certificate) : null
  passphrase         = lookup(each.value, "passphrase", null) != null ? each.value.passphrase : null
  private_key        = lookup(each.value, "private_key", null) != null ? file(each.value.private_key) : null
  public_certificate = lookup(each.value, "public_certificate", null) != null ? file(each.value.public_certificate) : null

  lifecycle {
    create_before_destroy = true
  }
}

