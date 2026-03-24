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
# VPC
# ==========================================================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "${var.aws_name_tag}-vpc"
    ManagedBy = "terraform"
  }
}

# ==========================================================================
# Internet Gateway
# ==========================================================================
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.aws_name_tag}-igw"
    ManagedBy = "terraform"
  }
}

# ==========================================================================
# Public Subnet
# ==========================================================================
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name      = "${var.aws_name_tag}-public-subnet"
    ManagedBy = "terraform"
  }
}

# ==========================================================================
# Route Table (public → IGW)
# ==========================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name      = "${var.aws_name_tag}-public-rt"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
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
# Security Group — Lab/Application access (inside VPC)
# ==========================================================================
resource "aws_security_group" "lab_access" {
  name        = "${var.aws_name_tag}-sg"
  description = "Allow application traffic for ${var.aws_name_tag}"
  vpc_id      = aws_vpc.main.id

  # ---- SSH ----
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- HTTP ----
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- HTTPS ----
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- HTTP Alt (8080) ----
  ingress {
    description = "HTTP Alt - Tomcat / Jenkins / APIs"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- HTTPS Alt (8443) ----
  ingress {
    description = "HTTPS Alt"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- PostgreSQL ----
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- MySQL / MariaDB ----
  ingress {
    description = "MySQL / MariaDB"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- MongoDB ----
  ingress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- Redis ----
  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- ICMP (Ping) ----
  ingress {
    description = "ICMP - Ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- Egress — all traffic ----
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.aws_name_tag}-sg"
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
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.lab_access.id]
  associate_public_ip_address = true

  tags = {
    Name      = var.aws_instance_count > 1 ? "${var.aws_name_tag}-${count.index + 1}" : var.aws_name_tag
    Role      = var.aws_server_role
    Group     = var.aws_server_group
    ManagedBy = "terraform"
  }
}
