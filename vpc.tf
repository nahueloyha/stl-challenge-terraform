module "vpc_example_simple-vpc" {
  source  = "terraform-aws-modules/vpc/aws//examples/simple-vpc"
  version = "3.18.1"

  name   = "${var.namespace}-${var.environment}"

  cidr                 = "${var.vpc_cidr}.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]

  private_subnets = ["${var.vpc_cidr}.1.0/24", "${var.vpc_cidr}.2.0/24", "${var.vpc_cidr}.3.0/24"]
  public_subnets  = ["${var.vpc_cidr}.101.0/24", "${var.vpc_cidr}.102.0/24", "${var.vpc_cidr}.103.0/24"]
  database_subnets =  ["${var.vpc_cidr}.201.0/24", "${var.vpc_cidr}.202.0/24", "${var.vpc_cidr}.203.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = true

}
