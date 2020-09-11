
terraform {
  backend "consul" {}
}

data "openstack_networking_router_v2" "publicrouter" {
  name = var.router_name
}


resource "openstack_networking_network_v2" "extnet" {
  name           = var.extnet
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "extsubnet" {
  name       = var.ext_subnet
  network_id = openstack_networking_network_v2.extnet.id
  cidr       = var.ext_cidr
  dns_nameservers = var.ext_dns
  ip_version = 4
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = data.openstack_networking_router_v2.publicrouter.id
  subnet_id = openstack_networking_subnet_v2.extsubnet.id
}

resource "openstack_networking_network_v2" "net" {
  for_each = var.networks
  name           = each.value.network
  admin_state_up = "true"
  port_security_enabled = true
}

resource "openstack_networking_subnet_v2" "subnet" {
  for_each = var.networks
  name       = each.value.subnet
  network_id = openstack_networking_network_v2.net[each.key].id
  cidr       = each.value.cidr
  dns_nameservers = each.value.dns
  ip_version = 4
}


module "host" {
  source = "git@git-service.ait.ac.at:sct-cyberrange/terraform-modules/openstack-srv_noportsec.git?ref=v1.3"
  hostname = var.host_name
  tag = var.host_tag
  host_address_index = var.host_ext_ip
  image = var.host_image
  flavor = var.host_flavor
  sshkey = var.sshkey
  network = var.extnet
  subnet = var.ext_subnet
  userdatafile = var.host_userdata
  additional_networks = var.networks
  depends_on = [ openstack_networking_network_v2.net, openstack_networking_subnet_v2.subnet, openstack_networking_network_v2.extnet, openstack_networking_subnet_v2.extsubnet ]
}

resource "openstack_networking_floatingip_v2" "floatip_1" {
	count = var.use_floatingip ? 1 : 0
	pool = "provider-aecid-208"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
	count = var.use_floatingip ? 1 : 0
	floating_ip = openstack_networking_floatingip_v2.floatip_1[0].address
	instance_id = module.host.server.id
	depends_on = [module.host]
}
