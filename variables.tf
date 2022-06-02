variable "region" {
  type        = string
  description = "Region"
  default     = "eu-frankfurt-1"
}
variable "compartment_id" {
  type        = string
  description = "compartment OCID to use for resources ."
}

variable "prefix" {
  type    = string
  default = "none"

}

variable "create_vcn" {
  type        = bool
  description = "Create vcn or not"
  default     = true
}
variable "vcn_cidrs" {
  type        = list(string)
  description = "VCN CIDR"
  default     = ["10.0.0.0/16"]
}
variable "subnets" {
  type = any
  default = {
    lbsubnet = { cidr_block = "10.0.1.0/28" }
  }
}

variable "lb_options" {
  type        = any
  description = "lb options"
}

variable "listeners" {
  type        = any
  description = "loadbalancer listener"
}
variable "cert_lb" {
  type        = any
  description = "Loadbalancer certificate"
  default     = {}
}

variable "backend_sets" {
  type = any
}

variable "waf_policy_display_name" {
  type    = string
  default = "wafpolicy"
}

variable "waf_web_app_firewall" {
  type    = string
  default = "waf_firewall"
}

variable "vcn_id" {
  type        = string
  description = "Existing VCN id"
  default     = ""
}

variable "ig_route_id" {
  type        = string
  description = "Existing Internet Gateway route Id"
  default     = ""
}

variable "nat_route_id" {
  type        = string
  description = "Existinng NAT Gateway route id"
  default     = ""
}
