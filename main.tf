
terraform {
  backend "consul" {}
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


