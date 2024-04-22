# Create a network and a subnet for all networks specified in "other_networks"
# Therefore the module os.network is used, which creates them and returns the network_id and subnet_id (see "Link to os.network")
module "networks" {
    source        = "git@github.com:ait-cs-IaaS/terraform-openstack-network.git"
    for_each      = var.child_networks
    name          = each.value.name
    cidr          = each.value.cidr
    dns_nameservers = each.value.dns_nameservers # make default?
}

# Here a local value "networks" is created, which contains information (name, cidr, ids) about the networks that were created before
locals {
  networks = {
    for key, value in module.networks : key => {
        name = value.network_name
        cidr = value.network_cidr
        host_index = 1 # create a variable for that and use 1 just as default
        network_id = value.network_id
        subnet_id = value.subnet_id
    }
  }
}

# Create the server between the networks, that acts as router and firewall.
# Therefore the module os.server is used, which creates the machine and associated ports in all networks 
module "firewall" {
    source        = "git@github.com:ait-cs-IaaS/terraform-openstack-srv_noportsec.git"
    name = var.firewall_name
    cidr = var.parent_cidr
    host_index = var.firewall_host_index #create a variable for that and use 254 just as default
    network_id = var.parent_network_id
    subnet_id = var.parent_subnet_id
    image = var.firewall_image
    flavor = var.firewall_flavor
    userdata = file("${path.module}/scripts/firewall_init.yml")
    additional_networks = local.networks
}

# Create the routes --> define that the next from the base net to the other nets is over the firewall created before.
resource "openstack_networking_subnet_route_v2" "subnet_route" {
  count            = length(var.destinations)
  subnet_id        = var.parent_subnet_id
  destination_cidr = var.destinations[count.index]
  next_hop         = cidrhost(var.parent_cidr, var.firewall_host_index)
}