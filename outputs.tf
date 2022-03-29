output "firewall" {
  value     = module.host.server
  sensitive = true
}

output "extnet" {
  value = {
    network = var.extnet
    subnet  = var.ext_subnet
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
