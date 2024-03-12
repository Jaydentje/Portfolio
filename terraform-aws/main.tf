#module "awsgob" {
#  // location of the module - can be local or git repo
#  source = "modules/gobmdls"
#
#  # - Cognito -
#  # Admin Users to create
#  gob_admin_cognito_users = {
#    GJayden : {
#      username       = "admin"
#      given_name     = "Default"
#      family_name    = "Admin"
#      email          = "jaydengunhan@gmail.com"
#      email_verified = true
#    }
#  }
#
#  # Standard Users to create
#  gob_standard_cognito_users = {
#    DefaultStandardUser : {
#      username       = "default"
#      given_name     = "Default"
#      family_name    = "User"
#      email          = "example@example.com"
#      email_verified = false
#    }
#  }
#}

# Create a VPC
resource "aws_vpc" "gob_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "learning"
  }
}

resource "aws_subnet" "gob_subnet" {
  vpc_id                  = aws_vpc.gob_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "learning-public"
  }
}

resource "aws_internet_gateway" "gob_igw" {
  vpc_id = aws_vpc.gob_vpc.id

  tags = {
    Name = "learning-igw"
  }
}

resource "aws_route_table" "gob_rt" {
  vpc_id = aws_vpc.gob_vpc.id

  tags = {
    Name = "learning-rt"
  }
}

resource "aws_route" "default_rt" {
  route_table_id         = aws_route_table.gob_rt.id
  gateway_id             = aws_internet_gateway.gob_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "gob_public_rta" {
  subnet_id      = aws_subnet.gob_subnet.id
  route_table_id = aws_route_table.gob_rt.id
}

resource "aws_security_group" "gob_sg" {
  name        = "gob_sg"
  description = "gob security group"
  vpc_id      = aws_vpc.gob_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # heh
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "learning-sg"
  }
}

resource "aws_key_pair" "gob_auth" {
    key_name   = "gobkey"
    public_key = file("~/.ssh/gobkey.pub")
}

resource "aws_instance" "gob_instance" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.server_ami.id
  key_name      = aws_key_pair.gob_auth.id
  subnet_id     = aws_subnet.gob_subnet.id
  vpc_security_group_ids = [aws_security_group.gob_sg.id]

  tags = {
    Name = "learning-node"
  }

  root_block_device {
    volume_size = 10
  }
}