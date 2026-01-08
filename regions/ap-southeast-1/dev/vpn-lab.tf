# locals {
#   vpc_id      = "vpc-09b7e1fd7b675df68"
#   subnet_id   = "subnet-0dd9fdf602d7c070f"
# }

# VPC
resource "aws_vpc" "main" {
  cidr_block            = "172.17.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = { Name = "${local.prefix}" }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.17.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1a"

  tags = { Name = "${local.prefix}-public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags   = { Name = "${local.prefix}-public-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${local.prefix}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${local.prefix}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.17.2.0/24"
  availability_zone       = "ap-southeast-1a"

  tags = { Name = "${local.prefix}-private-subnet" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${local.prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_key_pair" "my_key" {
  key_name   = "mykey"                          # The name that will appear in AWS
  public_key = file("~/.ssh/id_rsa.pub")        # Path to your local public key
}



# Public security group
resource "aws_security_group" "public_sg" {
  name   = "${local.prefix}-public-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 500
    to_port     = 500
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 4500
    to_port     = 4500
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 51820
    to_port     = 51820
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   protocol    = "icmp"
  #   from_port   = 0
  #   to_port     = 0
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-public-sg"
  }
}

# Public EC2 instance
resource "aws_instance" "public_ec2" {
  ami                         = local.amz_ubuntu_24_04_ami
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  key_name                    = aws_key_pair.my_key.key_name

  source_dest_check           = false  # REQUIRED for routing

  tags = {
    Name = "${local.prefix}-public-instance"
  }
}



# Private security group
resource "aws_security_group" "private_sg" {
  name   = "${local.prefix}-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Private EC2 instance
resource "aws_instance" "private_ec2" {
  ami                         = local.amz_linux_2023_ami
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  key_name                    = aws_key_pair.my_key.key_name

  tags = {
    Name = "${local.prefix}-private-ec2"
  }
}

