# =============================================================================
# REQUIRED INPUTS - PROVIDED BY THE MAIN MODULE
# =============================================================================

variable "compartment_ocid" {
  description = "Oracle Cloud compartment ID - where to create our servers"
  type        = string
  # Example: "ocid1.compartment.oc1..aaaaaa..."
}

variable "subnet_ocids" {
  description = "Map of network subnet IDs from the network module"
  type        = map(string)
  # Contains: public_a, public_b, private_web subnet IDs
  # Example: { public_a = "ocid1.subnet...", private_web = "ocid1.subnet..." }
}

variable "public_ssh_key" {
  description = "Your SSH public key content (from ~/.ssh/id_rsa.pub)"
  type        = string
  # This key will be installed on all servers for secure SSH access
}

# =============================================================================
# SERVER HARDWARE CONFIGURATION
# =============================================================================

variable "vm_shape" {
  description = "Server type/size (like choosing a car model)"
  type        = string
  # Example: "VM.Standard.E4.Flex" = Flexible ARM-based server
}

variable "flex_ocpus" {
  description = "Number of CPU cores per server (1-64 cores available)"
  type        = number
  # Example: 1 = single core (good for demo/dev)
}

variable "flex_memory" {
  description = "RAM memory in GB per server (1-1000 GB available)"
  type        = number
  # Example: 8 = 8GB RAM (good for demo/dev)
}

# =============================================================================
# SHARED CONFIGURATION
# =============================================================================

variable "common_tags" {
  description = "Standard tags applied to all servers (for organization & billing)"
  type        = map(string)
  default     = {}
  # Example: { Environment = "dev", Project = "demo", ManagedBy = "terraform" }
}

variable "web_count" {
  description = "Number of web servers to create (varies by workspace)"
  type        = number
  # dev = 1 server, staging = 2 servers (for load balancing demo)
}

# =============================================================================
# CUSTOMIZATION VARIABLES
# =============================================================================

variable "bastion_name" {
  description = "Custom name for the bastion host"
  type        = string
  default     = "bastion-host"
}

variable "web_name_prefix" {
  description = "Prefix for web server names"
  type        = string
  default     = "web-server"
}

variable "operating_system" {
  description = "Operating System for all servers"
  type        = string
  default     = "Oracle Linux"
}

variable "os_version" {
  description = "Operating System version"
  type        = string
  default     = "8"
}