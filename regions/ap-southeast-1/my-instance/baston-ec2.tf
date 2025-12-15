locals {
  vpc_id      = "vpc-09b7e1fd7b675df68"
  subnet_id   = "subnet-0dd9fdf602d7c070f"
}

resource "aws_key_pair" "my_key" {
  key_name   = "mykey"                          # The name that will appear in AWS
  public_key = file("~/.ssh/id_rsa.pub")        # Path to your local public key
}

resource "aws_security_group" "bastion_sg" {
  name   = "nam-documentdb-bastion-sg"
  vpc_id = local.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_instance" "public_ec2" {
  ami                         = local.ami
  instance_type               = "t2.small"
  subnet_id                   = local.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.my_key.key_name

  tags = {
    Name = "nam-documentdb-baston"
  }
}

