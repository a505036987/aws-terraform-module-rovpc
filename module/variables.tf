variable "wssdev-vpc" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "public_sn_count" {
  type    = number
}

variable "private_sn_count" {
  type    = number
}

variable "workspace_sn_count" {
  type    = number
}
