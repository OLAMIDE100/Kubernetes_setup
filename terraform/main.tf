terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = "eu-central-1"
}



################################################################################################################### VPC & SUBNET CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################
resource "aws_vpc" "master" {
  cidr_block                           = "10.0.0.0/22"
  tags = {
    Name = "cluster-test"
  }
}



resource "aws_subnet" "master-subnet" {
  availability_zone                              = "eu-central-1a"
  cidr_block                                     = "10.0.0.0/26"
  tags = {
    Name = "master-subnet-test"
  }
  vpc_id = aws_vpc.master.id
}



resource "aws_subnet" "worker-subnet" {
  availability_zone                              = "eu-central-1b"
  cidr_block                                     = "10.0.1.0/26"

  tags = {
    Name = "worker-subnet-test"
  }

  vpc_id = aws_vpc.master.id
}



################################################################################################################### INTERNET GATEWAY CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################


resource "aws_internet_gateway" "master-igw" {
  tags = {
    Name = "master-igw-test"
  }
}


resource "aws_internet_gateway_attachment" "example" {
  internet_gateway_id = aws_internet_gateway.master-igw.id
  vpc_id              = aws_vpc.master.id
}



################################################################################################################### ROUTE TABLE CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################
resource "aws_route_table" "general-rt" {
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.master-igw.id
  
  }
  tags = {
    Name = "master-route-table-test"
  }

  vpc_id              = aws_vpc.master.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.worker-subnet.id
  route_table_id = aws_route_table.general-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.master-subnet.id
  route_table_id = aws_route_table.general-rt.id
}
################################################################################################################### SECURITY GROUP CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_security_group" "worker" {
  description = "security group for the worker nodes"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      =  ""
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
  }]

  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "shh traffic"
    from_port        = 22
    protocol         = "tcp"
    to_port          = 22
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "traffic for the nodeports"
    from_port        = 30000
    protocol         = "tcp"
    to_port          = 32767
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "weavenet udp"
    from_port        = 6783
    protocol         = "udp"
    to_port          = 6784
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["10.0.0.0/22"]
    description      = "traffic for the kublet"
    from_port        = 1250
    protocol         = "tcp"
    to_port          = 1250
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["10.0.0.0/22"]
    description      = "weavenet tcp"
    from_port        = 6783
    protocol         = "tcp"
    to_port          = 6783
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
  }]
  name                   = "worker-test"
  vpc_id                 = aws_vpc.master.id
}


resource "aws_security_group" "master" {
  description = "for control plane port and protocol"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
  }]
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "all traffic to kubeapi server"
    from_port        = 6443
    protocol         = "tcp"
    to_port          = 6443
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "ssh all traffic"
    from_port        = 22
    protocol         = "tcp"
    to_port          = 22
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "weavenet udp"
    from_port        = 6783
    protocol         = "udp"
    to_port          = 6784
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["10.0.0.0/22"]
    description      = "traffic inside vpc for etcd database"
    from_port        = 2379
    protocol         = "tcp"
    to_port          = 2380
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["10.0.0.0/22"]
    description      = "traffic inside vpc for kubelet, kube-scheduler,kube-controller"
    from_port        = 10250
    protocol         = "tcp"
    to_port          = 10259
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = ["10.0.0.0/22"]
    description      = "weavenet tcp"
    from_port        = 6783
    protocol         = "tcp"
    to_port          = 6783
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
  }]
  name                   = "master-test"
  vpc_id                 = aws_vpc.master.id
}


################################################################################################################### VIRTUAL MACHINE CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################




resource "aws_instance" "master" {
  ami = "ami-0e04bcbe83a83792e"
  associate_public_ip_address          = false
  availability_zone                    = "eu-central-1a"
  instance_type                        = "t2.medium"
  subnet_id                            = aws_subnet.master-subnet.id
  key_name                             = "admin"
  tags = {
    Name = "master-test"
  }
  vpc_security_group_ids      = [aws_security_group.master.id]
  
 
 
 
}


resource "aws_instance" "worker-2" {
  ami = "ami-0e04bcbe83a83792e"

  availability_zone                    = "eu-central-1b"
  instance_type                        = "t2.micro"
  key_name                             = "admin"
  subnet_id                            = aws_subnet.worker-subnet.id
  tags = {
    Name = "worker-2-test"
  }
  vpc_security_group_ids      = [aws_security_group.worker.id]
 
 

  
}


resource "aws_instance" "worker-1" {
  ami = "ami-0e04bcbe83a83792e"

  availability_zone                    = "eu-central-1b"
  instance_type                        = "t2.micro"
  key_name                             = "admin"
  subnet_id                            = aws_subnet.worker-subnet.id
  tags = {
    Name = "worker-1-test"
  }
  vpc_security_group_ids      = [aws_security_group.worker.id]
 
  

 
}
