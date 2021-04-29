output "firewall" {
  value     = module.host.server
  sensitive = true
}

output "extnet" {
  value = {
    network = var.extnet_create ? openstack_networking_network_v2.extnet[0].id : var.extnet
    subnet  = var.extnet_create ? openstack_networking_subnet_v2.extsubnet[0].id : var.ext_subnet
  }
}

output "networks" {
  value = {
    for name, network in var.networks :
    name => {
      network = openstack_networking_network_v2.net[name]
      subnet  = openstack_networking_subnet_v2.subnet[name]
    }
  }
}
