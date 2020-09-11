# Terraform-module: openstack-vmnets

This module creates an "external" network and multiple "internal" networks with a virtual machine in between. This
could be useful if a custom firewall-virtualmachine is needed.

# Configuration


```
terraform {
    source = "/home/hw/Projekte/Anomalie/Testbed/terragrunt/modules/openstack-networks/"
}

inputs = {
    host_name = "inet-firewall"
    host_image = "aecid-ubuntu-bionic-amd64"
    host_tag = "firewall"
    host_ext_ip = "100"
    host_userdata = "test.yml"
    ext_subnet = "testsubnet"
    extnet = "testnet"
    sshkey = "testbed-key"
    use_floatingip = true
    networks = {
        local = {
                network = "local",
                host_address_index = "1",
                subnet = "local-subnet",
                cidr = "172.16.0.0/24",
                dns: ["8.8.8.8"]
        }
        dmz = {
                network = "dmz",
                host_address_index = "1",
                subnet = "dmz-subnet"
                cidr = "172.16.100.0/24"
                dns: ["8.8.8.8"]
        }
    }
}

include {
  path = find_in_parent_folders()
}
```
