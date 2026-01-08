# # VPC
# resource "aws_vpc" "main" {
#   cidr_block            = "172.17.0.0/16"
#   enable_dns_hostnames  = true
#   enable_dns_support    = true

#   tags = { Name = "${local.prefix}" }
# }

# # Public subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "172.17.1.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "ap-southeast-1a"

#   tags = { Name = "${local.prefix}-public-subnet" }
# }

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id

#   tags   = { Name = "${local.prefix}-public-igw" }
# }

# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }

#   tags = { Name = "${local.prefix}-public-rt" }
# }

# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# resource "aws_eip" "nat" {
#   domain = "vpc"

#   tags = {
#     Name = "${local.prefix}-nat-eip"
#   }
# }

# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public.id

#   tags = {
#     Name = "${local.prefix}-nat-gateway"
#   }

#   depends_on = [aws_internet_gateway.igw]
# }

# # Private subnet
# resource "aws_subnet" "private" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "172.17.2.0/24"
#   availability_zone       = "ap-southeast-1a"

#   tags = { Name = "${local.prefix}-private-subnet" }
# }

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat.id
#   }

#   tags = {
#     Name = "${local.prefix}-private-rt"
#   }
# }

# resource "aws_route_table_association" "private_assoc" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }

# # Key-pair
# resource "aws_key_pair" "my_key" {
#   key_name   = "mykey"                          # The name that will appear in AWS
#   public_key = file("~/.ssh/id_rsa.pub")        # Path to your local public key
# }

# # Role
# resource "aws_iam_role" "ec2_role" {
#   name = "${local.prefix}-ec2-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Policies to Role
# resource "aws_iam_role_policy_attachment" "s3_full_access" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }

# # Instance profile
# resource "aws_iam_instance_profile" "ec2_profile" {
#   name = "${local.prefix}-ec2-instance-profile"
#   role = aws_iam_role.ec2_role.name
# }

# # Public security group
# resource "aws_security_group" "public_sg" {
#   name        = "${local.prefix}-public-sg"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["${local.my_ip}"]
#   }

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = { Name = "${local.prefix}-public-sg" }
# }

# # Public EC2 instance
# resource "aws_instance" "public_ec2" {
#   ami                         = local.amz_linux_2023_ami
#   instance_type               = "t2.small"
#   subnet_id                   = aws_subnet.public.id
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.public_sg.id]
#   key_name                    = aws_key_pair.my_key.key_name
#   iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

#   #   # Simple userdata to install nginx and serve a landing page
#   #   user_data = <<-EOF
#   #     #!/bin/bash
#   #     yum update -y
#   #     EOF

#   tags = {
#     Name = "${local.prefix}-public-ec2"
#   }
# }

# # Private security group
# resource "aws_security_group" "private_sg" {
#   name   = "${local.prefix}-ec2-sg"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     description     = "SSH from bastion"
#     from_port       = 22
#     to_port         = 22
#     protocol        = "tcp"
#     security_groups = [aws_security_group.public_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # Private EC2 instance
# resource "aws_instance" "private_ec2" {
#   ami                         = local.amz_linux_2023_ami
#   instance_type               = "t2.small"
#   subnet_id                   = aws_subnet.private.id
#   vpc_security_group_ids      = [aws_security_group.private_sg.id]
#   key_name                    = aws_key_pair.my_key.key_name
#   iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

#   #   # Simple userdata to install nginx and serve a landing page
#   #   user_data = <<-EOF
#   #     #!/bin/bash
#   #     yum update -y
#   #     EOF

#   tags = {
#     Name = "${local.prefix}-private-ec2"
#   }
# }
