data "aws_route53_zone" "main" {
  name = "subcloudlabs.com"
}

data "aws_lb" "shared" {
  name  = "shared-alb"
}

resource "aws_route53_record" "wildcard" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.subcloudlabs.com"
  type    = "A"

  alias {
    name                   = data.aws_lb.shared.dns_name
    zone_id                = data.aws_lb.shared.zone_id
    evaluate_target_health = true
  }
}