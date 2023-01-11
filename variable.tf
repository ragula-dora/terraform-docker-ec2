variable "count" {
 default = 1
 }
variable "region" {
 description = "AWS region for hosting our your network"
 default = "us-east-2"
}
variable "key_name" {
 description = "Key name for SSHing into EC2"
 default = "kaypair_name"
}
