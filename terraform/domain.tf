resource "aws_route53_zone" "primary" {
  name = var.app_domain

  tags = {
    Name = var.app_domain
  }
}
