module "ec2_bastion" {
  source = "cloudposse/ec2-bastion-server/aws"
  version = "0.30.1"
  name = "${local.name}-ec2"

  ami = "ami-09d3b3274b6c5d4aa"

  instance_type               = "t2.micro"
  security_groups             = [module.sg_bastion.security_group_id]
  subnets                     = module.vpc.public_subnets
  key_name                    = "stl-challenge"
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = true

}

module "sg_bastion" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "${local.name}-ec2"
  description = "SG for EC2"
  vpc_id      = module.vpc.vpc_id
  
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access from Nahuel IP"
      cidr_blocks = "186.189.239.0/24"
    }
  ]

  tags = local.tags
}