

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

  # UUID regex used to check if lookup dependencies by name or already have the id
  is_uuid = "[0-9a-fA-F]{8}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{12}"
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
  gateway_ip      = var.ext_gateway_index != null ? cidrhost(var.ext_cidr, var.ext_gateway_index) : null
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
  gateway_ip = each.value.host_address_index != null ? cidrhost(each.value.cidr, each.value.host_address_index) : null
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

data "openstack_networking_network_v2" "extnet" {
  count = var.extnet_create ? 0 : 1
  # load by ID if we got a UUID and by name if not
  name       = can(regex(local.is_uuid, var.extnet)) ? null : var.extnet
  network_id = can(regex(local.is_uuid, var.extnet)) ? var.extnet : null
}

data "openstack_networking_subnet_v2" "extsubnet" {
  count = var.extnet_create ? 0 : 1
  # load by ID if we got a UUID and by name if not
  name      = can(regex(local.is_uuid, var.ext_subnet)) ? null : var.ext_subnet
  subnet_id = can(regex(local.is_uuid, var.ext_subnet)) ? var.ext_subnet : null
}


locals {
  external_cidr   = var.extnet_create ? var.ext_cidr : data.openstack_networking_subnet_v2.extsubnet[0].cidr
  ext_host_routes = var.extnet_create ? var.ext_routes : data.openstack_networking_subnet_v2.extsubnet[0].host_routes
  network_userdata = {
    "external_network_id" = var.extnet_create ? openstack_networking_network_v2.extnet[0].id : data.openstack_networking_network_v2.extnet[0].id
    "external_subnet_id"  = var.extnet_create ? openstack_networking_subnet_v2.extsubnet[0].id : data.openstack_networking_subnet_v2.extsubnet[0].id
    "external_network" = {
      ip     = var.host_ext_address_index != null ? cidrhost(local.external_cidr, var.host_ext_address_index) : null
      cidr   = local.external_cidr
      dns    = var.extnet_create ? var.ext_dns : data.openstack_networking_subnet_v2.extsubnet[0].dns_nameservers
      routes = var.ext_fw_routes != null ? var.ext_fw_routes : local.ext_host_routes
      gw     = var.extnet_create ? openstack_networking_subnet_v2.extsubnet[0].gateway_ip : data.openstack_networking_subnet_v2.extsubnet[0].gateway_ip
    }
    "networks" = {
      for key, network in var.networks : key => {
        id        = openstack_networking_network_v2.net[key].id
        subnet_id = openstack_networking_subnet_v2.subnet[key].id
        ip        = network.host_address_index != null ? cidrhost(network.cidr, network.host_address_index) : null
        cidr      = network.cidr
        dns       = network.host_address_index != null && network.host_as_dns ? concat([cidrhost(network.cidr, network.host_address_index)], coalesce(network.dns, [])) : network.dns
        routes    = network.fw_routes != null ? network.fw_routes : network.routes
      }
    }
    "network_ids" = {
      for key, network in var.networks : openstack_networking_network_v2.net[key].id => key
    }
  }
}

module "host" {
  source             = "git@git-service.ait.ac.at:sct-cyberrange/terraform-modules/openstack-srv_noportsec.git?ref=v1.4.2"
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
  userdata_vars      = var.host_userdata_vars != null ? merge(local.network_userdata, var.host_userdata_vars) : local.network_userdata
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
