
terraform {
  backend "consul" {}
}

locals {
  # convert host routes into a flat list
  # we need to do this since we have multiple networks with possibly multiple routes
  # and terraform only supports one level for count/for_each
  host_routes = flatten([
    for net, conf in var.networks : [
      for route in(conf.routes != null ? conf.routes : []) : {
        # the per network route index to get a stable resource naming
        # to avoid unecessary changes when for example a single route is removed
        "${conf.network}-${index(conf.routes, route)}" = {
          key  = net
          cidr = route.cidr
          gw   = route.gw
        }
      }
  ]])

  # colapse the list of maps into a single map so we can use for_each
  host_routes_merged = {
    for host_route in local.host_routes : keys(host_route)[0] => values(host_route)[0]
  }
}

data "openstack_networking_router_v2" "publicrouter" {
  count = var.extnet_create ? 1 : 0
  name  = var.router_name
}

resource "openstack_networking_network_v2" "extnet" {
  count          = var.extnet_create ? 1 : 0
  name           = var.extnet
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "extsubnet" {
  count           = var.extnet_create ? 1 : 0
  name            = var.ext_subnet
  network_id      = openstack_networking_network_v2.extnet[0].id
  cidr            = var.ext_cidr
  dns_nameservers = var.ext_dns
  ip_version      = 4
}


resource "openstack_networking_subnet_route_v2" "ext_route" {
  count            = length(var.ext_routes)
  subnet_id        = var.extnet_create ? openstack_networking_subnet_v2.extsubnet[0].id : var.ext_subnet
  destination_cidr = var.ext_routes[count.index].cidr
  next_hop         = var.ext_routes[count.index].gw
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  count     = var.extnet_create ? 1 : 0
  router_id = data.openstack_networking_router_v2.publicrouter[0].id
  subnet_id = openstack_networking_subnet_v2.extsubnet[0].id
}

resource "openstack_networking_network_v2" "net" {
  for_each              = var.networks
  name                  = each.value.network
  admin_state_up        = "true"
  port_security_enabled = true
}

resource "openstack_networking_subnet_v2" "subnet" {
  for_each   = var.networks
  name       = each.value.subnet
  network_id = openstack_networking_network_v2.net[each.key].id
  cidr       = each.value.cidr
  # require host_address_index if dns option is true 
  # then concat expected IP address with either supplied list or empty list (coalesce takes first not null/empty value)
  dns_nameservers = each.value.host_address_index != null && each.value.host_as_dns ? concat([cidrhost(each.value.cidr, each.value.host_address_index)], coalesce(each.value.dns, [])) : each.value.dns
  ip_version      = 4
}

resource "openstack_networking_subnet_route_v2" "route" {
  for_each         = local.host_routes_merged
  subnet_id        = openstack_networking_subnet_v2.subnet[each.value.key].id
  destination_cidr = each.value.cidr
  next_hop         = each.value.gw
}

module "host" {
  source             = "git@github.com:ait-cs-IaaS/terraform-openstack-srv_noportsec.git?ref=v1.4.2"
  hostname           = var.host_name
  tag                = var.host_tag
  host_address_index = var.host_ext_address_index
  image              = var.host_image
  flavor             = var.host_flavor
  volume_size        = var.host_size
  use_volume         = var.host_use_volume
  sshkey             = var.sshkey
  network            = var.extnet_create ? openstack_networking_network_v2.extnet[0].id : var.extnet
  subnet             = var.extnet_create ? openstack_networking_subnet_v2.extsubnet[0].id : var.ext_subnet
  userdatafile       = var.host_userdata
  additional_networks = { for key, network in var.networks : key => {
    network            = openstack_networking_network_v2.net[key].id
    subnet             = openstack_networking_subnet_v2.subnet[key].id
    host_address_index = network.host_address_index
    }
  }
}

resource "openstack_networking_floatingip_v2" "floatip_1" {
  count = var.floating_ip_pool != null ? 1 : 0
  pool  = var.floating_ip_pool
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  count       = var.floating_ip_pool != null ? 1 : 0
  floating_ip = openstack_networking_floatingip_v2.floatip_1[0].address
  instance_id = module.host.server.id
}
