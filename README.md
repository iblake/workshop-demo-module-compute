# Compute Module

Creates the virtual machines (servers) for the application.

## What it creates

- **Bastion Host**: Secure SSH gateway to access private servers
- **Web Servers**: Application servers that run your website
- **Cloud-init**: Automatic server setup scripts

## Key Features

- **Bastion security**: Only way to SSH into private servers
- **Auto-scaling**: dev=1 server, staging=2 servers (using workspaces)
- **High availability**: Servers distributed across data centers
- **Automatic setup**: Servers install web server and demo app automatically

## Server Specifications

- **Type**: VM.Standard.E4.Flex (AMD processors)
- **CPU**: 1 core (configurable)
- **Memory**: 8GB RAM (configurable)
- **OS**: Oracle Linux 8 (configurable)

## Files

- `main.tf`: Creates bastion and web servers
- `variables.tf`: Server configuration options
- `file/userdata_web.sh`: Automatic server setup script
