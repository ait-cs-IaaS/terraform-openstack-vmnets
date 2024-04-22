######################
### PARENT NETWORK ###
######################
variable parent_network_id { type = string }
variable parent_subnet_id { type = string }
variable parent_cidr {type = string }

################
### FIREWALL ###
################ 
variable firewall_name { type = string }
variable firewall_image { type = string }
variable firewall_flavor { type = string }
variable firewall_host_index {
  type = number
  default = 254
  }

##################################
### CHILD NETWORKS AND ROUTING ###
##################################
variable child_networks {
  type = map(
    object({
      name  = string
      cidr  = string
      dns_nameservers = list(string)
    })
  )
}

variable destinations {
  type = list(string)
  default = []
}