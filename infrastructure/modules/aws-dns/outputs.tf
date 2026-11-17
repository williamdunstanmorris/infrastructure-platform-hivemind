output "certificate_arn" {
  value = aws_acm_certificate_validation.wildcard.certificate_arn
}

output "zone_arn" {
  value = aws_route53_zone.main.arn
}