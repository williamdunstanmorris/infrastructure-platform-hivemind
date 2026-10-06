resource "aws_route53_zone" "main" {
  name = "subcloudlabs.com"
}

resource "aws_acm_certificate" "certification" {
  domain_name = "subcloudlabs.com"
  validation_method = "DNS"
}

resource "aws_acm_certificate" "wildcard" {
  domain_name               = "*.subcloudlabs.com"
  subject_alternative_names = ["subcloudlabs.com"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {

  for_each = { for o in aws_acm_certificate.wildcard.domain_validation_options : o.domain_name => o }

  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [ for r in aws_route53_record.cert_validation : r.fqdn]
}
