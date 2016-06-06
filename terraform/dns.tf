resource "aws_route53_zone" "cirrus_pebble_subdomain" {
  name = "ci.cirrus.pebblecode.com"
}

resource "dnsimple_record" "cirrus_subdomain" {
  domain = "pebblecode.com"
  count = 4
  name = "ci.cirrus"
  value = "${element(aws_route53_zone.cirrus_pebble_subdomain.name_servers, count.index)}"
  type = "NS"
  ttl = 3600
}

output "name_servers" {
  value = "${join(",", aws_route53_zone.cirrus_pebble_subdomain.name_servers)}"
}
output "zone_id" {
  value = "${aws_route53_zone.cirrus_pebble_subdomain.zone_id}"
}

