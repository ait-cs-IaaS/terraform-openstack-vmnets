variable "networks" {
	type = map(
		object({
			network = string
			subnet = string
			cidr = string
			dns = list(string)
			host_address_index = number
		})
	)
}

variable "host_name" {
	type = string
	description = "Name of the virtual machine"
}

variable "host_tag" {
	type = string
	description = "Tag for the virtual machine"
}

variable "host_ext_ip" {
	type = number
	description = "External IP  for the virtual machine. This must be an ip from the extnet"
}

variable "host_image" {
	type = string
	description = "Name of the image to use for the virtual machine"
}

variable "host_userdata" {
	type = string
	description = "Userdata for the virtual machine"
}

variable "host_flavor" {
	type = string
	description = "Flavor of the virtual machine"
	default = "m1.large"
}

variable "host_size" {
	type = number
	description = "Disksize in gb of the virtual machine"
	default = 5
}

variable "host_delete_on_termination" {
	type = bool
	description = "Delete host on termination"
	default = false
}

variable "sshkey" {
	type = string
	description = "ssh key for the virtual machine"
}

variable "extnet" {
	type = string
	description = "Name or id of the network to connect the host to (if extnet_create=true always assumed to be name)"
}

variable "ext_subnet" {
	type = string
	description = "Name or id of the subnet to connect the host to (if extnet_create=true always assumed to be name)"
}

variable "extnet_create" {
	type = bool
	description = "Flag determining if extnet is created or pre-existing network is used (true -> create, false -> use existing)"
	default = false
}

variable "ext_cidr" {
	type = string
	description = "CIDR of the subnet to connect the host to (only needed if extnet_create=true)"
	default = "192.168.201.0/24"
}

variable "ext_dns" {
	type = list(string)
	description = "List of dns-servers (only needed if extnet_create=true)"
	default = ["8.8.8.8"]
}

variable "router_name" {
	type = string
	description = "Name of the public router to connect the ext_subnet to (only needed if extnet_create=true)"
	default = null
}

variable "floating_ip_pool" {
	type = string
	description = "The floating ip pool to use, if not set no floating ip will be assigned to the router host"
	default = null
}

