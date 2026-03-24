# ==========================================================================
# Outputs — consumed by Ansible for post-provisioning tasks
# ==========================================================================
output "server_info" {
  description = "Detailed info for each provisioned instance"
  value = [
    for i, inst in aws_instance.server : {
      name          = inst.tags["Name"]
      instance_id   = inst.id
      instance_type = inst.instance_type
      public_ip     = inst.public_ip
      private_ip    = inst.private_ip
      role          = inst.tags["Role"]
      group         = inst.tags["Group"]
    }
  ]
}

output "public_ips" {
  description = "List of public IPs for quick reference"
  value       = aws_instance.server[*].public_ip
}
