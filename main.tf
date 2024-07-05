# Create a network and a subnet for all networks specified in "other_networks"
# Therefore the module os.network is used, which creates them and returns the network_id and subnet_id (see "Link to os.network")
module "networks" {
    source        = "git@github.com:ait-cs-IaaS/terraform-openstack-network.git"
    for_each      = var.child_networks
    name          = each.value.name
    cidr          = each.value.cidr
    dns_nameservers = each.value.dns_nameservers # make default?
}

locals {
  # Here a local value "networks" is created, which contains information (name, cidr, ids) about the networks that were created before
  networks = {
    for key, value in module.networks : key => {
        name = value.network_name
        cidr = value.network_cidr
        host_index = 1 # create a variable for that and use 1 just as default
        network_id = value.network_id
        subnet_id = value.subnet_id
    }
  }

  # INPUT VALUES FOR RENDERING firewall_init script
  network_userdata = {
        "external_network_id" = var.parent_network_id
        "external_subnet_id"  = var.parent_subnet_id
        "external_network" = {
          ip     = cidrhost(var.parent_cidr, var.firewall_host_index)
          cidr   = var.parent_cidr
          dns    = var.parent_dns_nameservers # team dns server OR internet dns server #var.extnet_create ? var.ext_dns : data.openstack_networking_subnet_v2.extsubnet[0].dns_nameservers
          routes = [] #var.ext_fw_routes != null ? var.ext_fw_routes : local.ext_host_routes
          gw     = var.parent_gateway_ip #"10.0.0.1" # depends on the extnet #240.64.0.1 #var.extnet_create ? openstack_networking_subnet_v2.extsubnet[0].gateway_ip : data.openstack_networking_subnet_v2.extsubnet[0].gateway_ip
        }
        "networks" = {
          for key, network in module.networks : key => {
            id        = network.network_id
            subnet_id = network.subnet_id
            ip        = cidrhost(network.network_cidr, 1)
            cidr      = network.network_cidr
            dns       = network.network_dns_nameservers
            routes    = var.child_networks[key].destinations != null ? [ for destination in var.child_networks[key].destinations : {
                          cidr = destination
                          gw = cidrhost(network.network_cidr, 254)
                        } ] : null
          }
        }
        "network_ids" = {
          for key, network in module.networks : network.network_id => key
        }
      }

  routes_flatten = flatten([
    for key, network in module.networks : [
      var.child_networks[key].destinations != null ? [ for destination in var.child_networks[key].destinations : {
        cidr = destination
        gw = cidrhost(network.network_cidr, 254)
        subnet_id = network.subnet_id
      } ] : []
    ]
  ])

}

# Create the server between the networks, that acts as router and firewall.
# Therefore the module os.server is used, which creates the machine and associated ports in all networks 
module "firewall" {
    source = "git@github.com:ait-cs-IaaS/terraform-openstack-srv_noportsec.git"
    name = var.firewall_name
    cidr = var.parent_cidr
    host_index = var.firewall_host_index #create a variable for that and use 254 just as default
    network_id = var.parent_network_id
    subnet_id = var.parent_subnet_id
    image = var.firewall_image
    flavor = var.firewall_flavor
    metadata_groups = var.metadata_groups
    metadata_company_info = var.metadata_company_info
    #userdata = file("${path.module}/scripts/firewall_init.yml")
    userdata = templatefile("${path.module}/scripts/firewall_init.yml", local.network_userdata)
    additional_networks = local.networks
}

#Create the routes --> define that the next from the base net to the other nets is over the firewall created before.
resource "openstack_networking_subnet_route_v2" "subnet_route" {
    count            = length(local.routes_flatten)
    subnet_id        = local.routes_flatten[count.index].subnet_id
    destination_cidr = local.routes_flatten[count.index].cidr
    next_hop         = local.routes_flatten[count.index].gw
}