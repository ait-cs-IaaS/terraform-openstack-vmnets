# Terraform-module: terraform-openstack-vmnets

This module creates an "external" network and multiple "internal" networks with a virtual machine in between. This
could be useful if a custom firewall-virtualmachine is needed.

# Configuration


```
terraform {
  source = "git@github.com:ait-cs-IaaS/terraform-openstack-vmnets.git"
}

inputs = {
  host_name = "inet-firewall"
  host_image = "aecid-ubuntu-bionic-amd64"
  host_tag = "firewall"
  host_ext_address_index = 100
  host_userdata = "test.yml"
  ext_subnet = "testsubnet"
  extnet = "testnet"
  extnet_create = true
  sshkey = "testbed-key"
  floating_ip_pool = "provider-aecid-208"
  networks = {
    local = {
      network = "local",
      host_address_index = "1",
      subnet = "local-subnet",
      cidr = "172.16.0.0/24",
      dns = ["8.8.8.8"],
      host_as_dns = false
      routes = [
        {
          cidr = "192.168.42.0/24"
          gw   = "172.16.100.5"
        }
      ]
    }
    dmz = {
      network = "dmz",
      host_address_index = "1",
      subnet = "dmz-subnet"
      cidr = "172.16.100.0/24",
      dns = ["8.8.8.8"]
      host_as_dns = false
      routes = null
    }
  }
}

include {
  path = find_in_parent_folders()
}
```
