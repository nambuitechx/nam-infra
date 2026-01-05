locals {
  vpc_id      = "vpc-09b7e1fd7b675df68"
  subnet_id   = "subnet-0dd9fdf602d7c070f"
}

resource "aws_key_pair" "my_key" {
  key_name   = "mykey"                          # The name that will appear in AWS
  public_key = file("~/.ssh/id_rsa.pub")        # Path to your local public key
}

resource "aws_security_group" "vpn" {
  name   = "${local.prefix}-vpn-sg"
  vpc_id = local.vpc_id

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
    Name = "${local.prefix}-vpn-sg"
  }
}

resource "aws_instance" "vpn" {
  ami                         = local.amz_ubuntu_24_04_ami
  instance_type               = "t2.small"
  subnet_id                   = local.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.vpn.id]
  key_name                    = aws_key_pair.my_key.key_name

  source_dest_check           = false  # REQUIRED for routing

  tags = {
    Name = "${local.prefix}-vpn-instance"
  }
}

# resource "aws_eip" "vpn" {
#   domain = "vpc"

#   tags = {
#     Name = "${local.prefix}-vpn-ec2-eip"
#   }
# }

# resource "aws_eip_association" "vpn_eip_association" {
#   instance_id   = aws_instance.vpn.id
#   allocation_id = aws_eip.vpn.id
# }

