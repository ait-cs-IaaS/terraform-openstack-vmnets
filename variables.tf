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
	description = "Name of the network to connect the host to"
}

variable "ext_subnet" {
	type = string
	description = "Name of the subnet to connect the host to"
}

variable "ext_cidr" {
	type = string
	description = "CIDR of the subnet to connect the host to"
        default = "192.168.201.0/24"
}

variable "ext_dns" {
	type = list(string)
	description = "List of dns-servers"
	default = ["8.8.8.8"]
}
