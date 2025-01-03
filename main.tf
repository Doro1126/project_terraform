# TLS Private Key
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# AWS Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.deployer.public_key_openssh
}

# Local Private Key File
resource "local_file" "private_key" {
  content  = tls_private_key.deployer.private_key_pem
  filename = "./my-key.pem"
}

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MainVPC"
  }
}

# 서브넷 생성 (4개 AZ)
resource "aws_subnet" "pub-subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_1
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "pub-subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_2
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_subnet" "pri-subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_3
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "pri-subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_4
  availability_zone = "ap-northeast-1d"

  tags = {
    Name = "PrivateSubnet2"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "InternetGateway"
  }
}

# 라우팅 테이블
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.pub-subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.pub-subnet2.id
  route_table_id = aws_route_table.rt.id
}

# NAT Gateway 생성
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "NATEIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.pub-subnet.id

  tags = {
    Name = "NATGateway"
  }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "BastionEIP"
  }
}

resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "WebEIP"
  }
}

# Private Route Table
resource "aws_route_table" "pri-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route_table_association" "pri-a1" {
  subnet_id      = aws_subnet.pri-subnet1.id
  route_table_id = aws_route_table.pri-rt.id
}

resource "aws_route_table_association" "pri-a2" {
  subnet_id      = aws_subnet.pri-subnet2.id
  route_table_id = aws_route_table.pri-rt.id
}

# 보안 그룹 설정
resource "aws_security_group" "pub-sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.allowed_ip
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PublicSecurityGroup"
  }
}

resource "aws_security_group" "pri-sg" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "PrivateSecurityGroup"
  }
}

resource "aws_security_group" "db-sg" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "DatabaseSecurityGroup"
  }
}

# EC2 Instances
resource "aws_instance" "web" {
  ami                         = "ami-0ac6b9b2908f3e20d"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.pub-subnet.id
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.pub-sg.id]
  associate_public_ip_address = false
  user_data                   = file("${path.module}/install_websrv.sh")
  tags = { Name = "Web" }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0ac6b9b2908f3e20d"
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.pub-subnet2.id
  vpc_security_group_ids      = [aws_security_group.pub-sg.id]
  associate_public_ip_address = false
  user_data                   = file("${path.module}/install_bastion.sh")
  tags = { Name = "Bastion" }
}

# RDS 서브넷 그룹
resource "aws_db_subnet_group" "default" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.pri-subnet1.id, aws_subnet.pri-subnet2.id]
  tags = { Name = "RDSSubnetGroup" }
}

# RDS 인스턴스
resource "aws_db_instance" "db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.33"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  publicly_accessible    = false
}
