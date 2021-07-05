variable "networks" {
  type = map(
    object({
      network            = string
      subnet             = string
      cidr               = string
      dns                = list(string)
      host_address_index = number
      host_as_dns        = bool
      routes = list(object(
        {
          cidr = string
          gw   = string
        }
      ))
      fw_routes = list(object(
        {
          cidr = string
          gw   = string
        }
      ))
    })
  )
  description = "map of internal networks to be created. (Note that if host_as_dns is true host_address_index must not be null)"
}

variable "host_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "host_tag" {
  type        = string
  description = "Tag for the virtual machine"
}

variable "host_ext_address_index" {
  type        = number
  description = "External IP address index for the host"
  default     = null

}

variable "host_image" {
  type        = string
  description = "Name of the image to use for the virtual machine"
}

variable "host_userdata" {
  type        = string
  description = "Userdata for the virtual machine"
  default     = null
}

variable "host_userdata_vars" {
  type        = any
  description = "Userdata vars for the virtual machine"
  default     = null
}

variable "host_flavor" {
  type        = string
  description = "Flavor of the virtual machine"
  default     = "m1.small"
}

variable "host_size" {
  type        = number
  description = "Disksize in gb of the virtual machine (only relavant is host_use_volume=true)"
  default     = 5
}

variable "host_use_volume" {
  type        = bool
  description = "If the compute node use a volume or a root file"
  default     = false
}

variable "host_delete_on_termination" {
  type        = bool
  description = "Delete host on termination"
  default     = false
}

variable "sshkey" {
  type        = string
  description = "ssh key for the virtual machine"
}

variable "extnet" {
  type        = string
  description = "Name or id of the network to connect the host to (if extnet_create=true always assumed to be name)"
}

variable "ext_subnet" {
  type        = string
  description = "Name or id of the subnet to connect the host to (if extnet_create=true always assumed to be name)"
}

variable "extnet_create" {
  type        = bool
  description = "Flag determining if extnet is created or pre-existing network is used (true -> create, false -> use existing)"
  default     = false
}

variable "ext_cidr" {
  type        = string
  description = "CIDR of the subnet to connect the host to (only needed if extnet_create=true)"
  default     = "192.168.201.0/24"
}

variable "ext_dns" {
  type        = list(string)
  description = "List of dns-servers (only needed if extnet_create=true)"
  default     = ["8.8.8.8"]
}

variable "ext_gateway_index" {
  type        = number
  description = "The host index for the external networks default gateway (only used if extnet_create=true)"
  default     = null
}

variable "ext_routes" {
  type = list(object(
    {
      cidr = string
      gw   = string
    }
  ))
  description = "List of host routes to add to the external network. Note that to use this extsubnet must be an ID if extnet_create is not set!"
  default     = []
}

variable "ext_fw_routes" {
  type = list(object(
    {
      cidr = string
      gw   = string
    }
  ))
  description = "List of routes to use on the external network interface of the fw host!"
  default     = []
}

variable "router_name" {
  type        = string
  description = "Name of the public router to connect the ext_subnet to (only needed if extnet_create=true)"
  default     = null
}

variable "floating_ip_pool" {
  type        = string
  description = "The floating ip pool to use, if not set no floating ip will be assigned to the router host"
  default     = null
}

