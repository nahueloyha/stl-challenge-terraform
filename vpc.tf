module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name   = local.name

  cidr = "${var.vpc_cidr}.0.0/16"
  azs  = ["us-east-1a", "us-east-1b", "us-east-1c"]

  private_subnets  = ["${var.vpc_cidr}.1.0/24", "${var.vpc_cidr}.2.0/24", "${var.vpc_cidr}.3.0/24"]
  public_subnets   = ["${var.vpc_cidr}.101.0/24", "${var.vpc_cidr}.102.0/24", "${var.vpc_cidr}.103.0/24"]
  database_subnets =  ["${var.vpc_cidr}.201.0/24", "${var.vpc_cidr}.202.0/24", "${var.vpc_cidr}.203.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  tags = local.tags
}