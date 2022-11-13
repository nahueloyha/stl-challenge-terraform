resource "aws_route53_zone" "public_zone" {
    name    = "stl-${var.environment}.nahueloyha.com"
    comment = "Managed by Terraform"
}

resource "aws_route53_record" "bastion" {
    zone_id = aws_route53_zone.public_zone.id
    name = "bastion.stl-${var.environment}.nahueloyha.com"
    type = "A"
    ttl = 300
    records = [module.ec2_bastion.public_ip]
}

resource "aws_route53_record" "api" {
    zone_id = aws_route53_zone.public_zone.id
    name = "api.stl-${var.environment}.nahueloyha.com"
    type = "CNAME"
    ttl = 300
    records = [aws_lb.alb.dns_name]
}

resource "aws_route53_record" "db" {
    zone_id = aws_route53_zone.public_zone.id
    name = "db.stl-${var.environment}.nahueloyha.com"
    type = "CNAME"
    ttl = 300
    records = [module.db.db_instance_address]
}