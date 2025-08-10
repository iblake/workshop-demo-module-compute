# =============================================================================
# COMPUTE MODULE - CREATES VIRTUAL MACHINES (SERVERS)
# =============================================================================
# This module creates the actual servers that will run our applications:
#
# WHAT WE CREATE:
# 1. BASTION HOST  → SSH gateway in public subnet (secure entry point)
# 2. WEB SERVERS   → Application servers in private subnet (1 in dev, 2 in staging)
#
# WHY WE NEED THESE:
# - Bastion Host: Secure way to SSH into private servers (jump box)
# - Web Servers: Run our actual web applications, protected in private subnets
# =============================================================================

# =============================================================================
# DATA SOURCES - DISCOVER WHAT'S AVAILABLE IN ORACLE CLOUD
# =============================================================================
# Data sources let us ask Oracle Cloud: "What options do I have?"
# Think of it like asking "What neighborhoods are available?" or "What OS versions?"

# Ask Oracle Cloud: "What availability domains (data centers) exist in this region?"
# Availability domains = Different physical locations for high availability
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# Ask Oracle Cloud: "What's the latest operating system image for my server type?"
# This automatically finds the newest Oracle Linux image that works with our server shape
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.operating_system # "Oracle Linux"
  operating_system_version = var.os_version       # "8"
  shape                    = var.vm_shape         # "VM.Standard.E4.Flex"
}

# Calculate the image ID we'll use for all servers
locals {
  # Select the latest image ID from the search results
  # If no image found, use "fake-image-id" (for testing/validation)
  latest_image_id = length(coalesce(data.oci_core_images.oracle_linux.images, [])) > 0 ? data.oci_core_images.oracle_linux.images[0].id : "fake-image-id"
}

# =============================================================================
# BASTION HOST - THE SECURE SSH GATEWAY
# =============================================================================
# WHAT IS A BASTION HOST?
# - A "jump box" - the only server with public internet access for SSH
# - All other servers are private - you must SSH through the bastion to reach them
# - This is a security best practice: one hardened entry point instead of many


resource "oci_core_instance" "bastion" {
  compartment_id      = var.compartment_ocid                                                                                                                                                              # Where to create this server
  availability_domain = length(coalesce(data.oci_identity_availability_domains.ads.availability_domains, [])) > 0 ? data.oci_identity_availability_domains.ads.availability_domains[0].name : "fake-ad-1" # Which data center to use (first available)
  shape               = var.vm_shape                                                                                                                                                                      # Server type (CPU/memory specs)

  # Configure CPU and memory resources
  shape_config {
    ocpus         = var.flex_ocpus  # Number of CPU cores (1 for demo)
    memory_in_gbs = var.flex_memory # RAM in GB (8GB for demo)
  }

  # Security: Install our SSH public key for secure login
  metadata = {
    ssh_authorized_keys = var.public_ssh_key # Your public key from ~/.ssh/id_rsa.pub
  }

  display_name = var.bastion_name # Name shown in Oracle Cloud console

  # Choose the operating system (Oracle Linux 8 latest image)
  source_details {
    source_type = "image"               # Use a pre-built OS image
    source_id   = local.latest_image_id # The latest Oracle Linux image ID
  }

  # Network configuration: Place in PUBLIC subnet with internet access
  create_vnic_details {
    subnet_id        = var.subnet_ocids["public_a"] # Put in public subnet A
    assign_public_ip = true                         # Give it a public IP address
    display_name     = "bastion-vnic"               # Network card name
  }

  # Tags for organization and billing
  freeform_tags = merge(var.common_tags, {
    Role         = "bastion" # This server's purpose
    PublicAccess = "yes"     # Has internet access
  })
}

# =============================================================================
# WEB SERVERS - THE APPLICATION SERVERS
# =============================================================================
# WHAT ARE WEB SERVERS?
# - These servers run our actual web applications (websites, APIs, etc.)
# - They're in PRIVATE subnets = no direct internet access (security!)
# - They can only be reached through the load balancer (for web traffic) or bastion (for SSH)
#
# SCALING BY ENVIRONMENT:
# - dev workspace:     1 web server  (minimal for testing)
# - staging workspace: 2 web servers (test high availability)


resource "oci_core_instance" "web" {
  count          = var.web_count        # How many web servers to create (1 for dev, 2 for staging)
  compartment_id = var.compartment_ocid # Where to create these servers

  # HIGH AVAILABILITY: Distribute servers across different data centers
  # If we have multiple servers, put them in different availability domains
  # count.index = 0,1,2... so we cycle through available domains
  availability_domain = length(coalesce(data.oci_identity_availability_domains.ads.availability_domains, [])) > 0 ? data.oci_identity_availability_domains.ads.availability_domains[count.index % length(data.oci_identity_availability_domains.ads.availability_domains)].name : "fake-ad-${count.index + 1}"
  shape               = var.vm_shape # Same server type as bastion

  # CPU and memory configuration (same as bastion for consistency)
  shape_config {
    ocpus         = var.flex_ocpus  # CPU cores
    memory_in_gbs = var.flex_memory # RAM in GB
  }

  # Server initialization: SSH key + automatic setup script
  metadata = {
    ssh_authorized_keys = var.public_ssh_key                                   # SSH access through bastion
    user_data           = base64encode(file("userdata_web.sh")) # Script that installs/configures web server automatically (first boot cloud-init)
  }

  display_name = "${var.web_name_prefix}-${count.index + 1}" # Names: web-1, web-2, etc.

  # Operating system (same image as bastion)
  source_details {
    source_type = "image"
    source_id   = local.latest_image_id
  }

  # Network configuration: Place in PRIVATE subnet (no public IP!)
  create_vnic_details {
    subnet_id        = var.subnet_ocids["private_web"] # Private web subnet
    assign_public_ip = false                           # NO public IP = secure!
    display_name     = "web-${count.index + 1}-vnic"   # Network card name
  }

  # Tags for organization, monitoring, and billing
  freeform_tags = merge(var.common_tags, {
    Name         = "${var.web_name_prefix}-${count.index + 1}" # Server name
    Tier         = "web"                                       # Architecture tier
    ServerIndex  = tostring(count.index + 1)                   # Server number (1, 2, etc.)
    LoadBalanced = "yes"                                       # Receives traffic from load balancer
    OS           = "${var.operating_system} ${var.os_version}" # Operating system info
  })
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = oci_core_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "OCID of the bastion instance"
  value       = oci_core_instance.bastion.id
}

output "web_private_ips" {
  description = "Private IPs of all web servers"
  value       = [for w in oci_core_instance.web : w.private_ip]
}

output "web_instance_ids" {
  description = "OCIDs of all web server instances"
  value       = [for w in oci_core_instance.web : w.id]
}