variable "ssh_port" {
  description = "The port the server will use for ssh connections"
  default     = 22
}

resource "aws_eip" "nat" {
  count = 3
  vpc   = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                = "DynomiteDB VPC"
  cidr                = "10.0.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  reuse_nat_ips       = true                                                # <= Skip creation of EIPs for the NAT Gateways
  enable_nat_gateway  = true
  enable_vpn_gateway  = false
  single_nat_gateway  = false
  external_nat_ip_ids = ["${aws_eip.nat.*.id}"]                             # <= IPs specified here as input to the module

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "azs0" {
  ami                    = "ami-40d28157"
  instance_type          = "t2.micro"
  availability_zone      = "${module.vpc.azs[0]}"
  vpc_security_group_ids = ["${aws_security_group.DynomiteDBSG.id}"]
  subnet_id              = "${module.vpc.public_subnets[0]}"

  tags = {
    Name = "dynomite azs0"
  }
}

resource "aws_eip" "eip_azs0" {
  vpc                       = true
  instance                  = "${aws_instance.azs0.id}"
  associate_with_private_ip = "${aws_instance.azs0.private_ip}"
}

resource "aws_instance" "azs1" {
  ami                    = "ami-40d28157"
  instance_type          = "t2.micro"
  availability_zone      = "${module.vpc.azs[1]}"
  vpc_security_group_ids = ["${aws_security_group.DynomiteDBSG.id}"]
  subnet_id              = "${module.vpc.public_subnets[1]}"

  tags = {
    Name = "dynomite azs1"
  }
}

resource "aws_instance" "azs2" {
  ami                    = "ami-40d28157"
  instance_type          = "t1.micro"
  availability_zone      = "${module.vpc.azs[2]}"
  vpc_security_group_ids = ["${aws_security_group.DynomiteDBSG.id}"]
  subnet_id              = "${module.vpc.public_subnets[2]}"

  tags = {
    Name = "dynomite azs2"
  }
}

resource "aws_security_group" "DynomiteDBSG" {
  name        = "DynomiteDBSG"
  description = "DynomiteDB security group"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = "0"
    to_port     = "65535"
    protocol    = "TCP"
    cidr_blocks = ["${module.vpc.private_subnets_cidr_blocks[0]}"]
  }

  ingress {
    from_port   = "0"
    to_port     = "65535"
    protocol    = "TCP"
    cidr_blocks = ["${module.vpc.private_subnets_cidr_blocks[1]}"]
  }

  ingress {
    from_port   = "0"
    to_port     = "65535"
    protocol    = "TCP"
    cidr_blocks = ["${module.vpc.private_subnets_cidr_blocks[2]}"]
  }

  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
