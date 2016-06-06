variable "aws_access_key_id" {
type = "string"
}
variable "aws_secret_access_key" {
type = "string"
}
variable "aws_region" {
    type = "string"
    default =  "eu-west-1"
}
/*variable "source_access_ip" {*/
/*type = "string"*/
/*}*/
variable "ci_hostname" {
type = "string"
}
variable "ci_dns_zone_id" {
type = "string"
}
variable "bosh_password" {
  type = "string"
  default = "boshpassword"
}
variable "dnsimple_token" {
  type = "string"
}
variable "dnsimple_email" {
  type = "string"
}
/*variable "ssl_cert_arn" {*/
/*type = "string"*/
/*}*/
