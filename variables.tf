variable "key_name" {
  type    = string
  default = "wirevpn"
}

variable "mobile" {
  type    = bool
  default = false
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "region" {
  type    = string
  default = "us-east-1"
}