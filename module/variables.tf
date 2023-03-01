variable "wssdev-vpc" {
  default = "10.158.96.0/20"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "public_sn_count" {
  type    = number
  default = 2
}

variable "private_sn_count" {
  type    = number
  default = 2
}

variable "workspace_sn_count" {
  type    = number
  default = 2
}
