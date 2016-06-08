resource "aws_route53_zone" "inoket_subdomain" {
  name = "ci.inoket.com"
}

resource "dnsimple_record" "inoket_nameservers" {
  domain = "inoket.com"
  count = 4
  name = "ci"
  value = "${element(aws_route53_zone.inoket_subdomain.name_servers, count.index)}"
  type = "NS"
  ttl = 3600
}

output "name_servers" {
  value = "${join(",", aws_route53_zone.inoket_subdomain.name_servers)}"
}
output "zone_id" {
  value = "${aws_route53_zone.inoket_subdomain.zone_id}"
}

