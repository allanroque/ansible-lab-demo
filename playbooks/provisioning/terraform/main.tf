# ==========================================================================
# Data: Latest Amazon Linux 2023 AMI
# ==========================================================================
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==========================================================================
# SSH Key Pair
# ==========================================================================
resource "aws_key_pair" "deployer" {
  key_name   = "${var.aws_name_tag}-key"
  public_key = var.aws_instance_public_key

  tags = {
    Name      = "${var.aws_name_tag}-key"
    ManagedBy = "terraform"
  }
}

# ==========================================================================
# Security Group — SSH access
# ==========================================================================
resource "aws_security_group" "allow_ssh" {
  name        = "${var.aws_name_tag}-ssh"
  description = "Allow SSH inbound traffic for ${var.aws_name_tag}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.aws_name_tag}-ssh"
    Role      = var.aws_server_role
    Group     = var.aws_server_group
    ManagedBy = "terraform"
  }
}

# ==========================================================================
# EC2 Instances
# ==========================================================================
resource "aws_instance" "server" {
  count                       = var.aws_instance_count
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.aws_instance_size
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name      = var.aws_instance_count > 1 ? "${var.aws_name_tag}-${count.index + 1}" : var.aws_name_tag
    Role      = var.aws_server_role
    Group     = var.aws_server_group
    ManagedBy = "terraform"
  }
}
