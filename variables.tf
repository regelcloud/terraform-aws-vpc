### Required Variables

variable "aws_region" {
  type        = "string"
  description = "AWS Region"
}

variable "cidr_block" {
  type = string
}

variable "public_subnet_base_cidr" {
  type = "string"
}

variable "public_subnet_cidr_split" {
  type = "string"
}

variable "private_subnet_base_cidr" {
  type = "string"
}

variable "private_subnet_cidr_split" {
  type = "string"
}

### Optional Variables
variable "instance_tenancy" {
  type    = string
  default = "default"
  #Alloed values: dedicated, default, host
}

variable "enable_dns_support" {
  type    = bool
  default = true
}


variable "enable_dns_hostnames" {
  type    = bool
  default = false
}

variable "enable_classiclink" {
  type    = bool
  default = false
}


variable "enable_classiclink_dns_support" {
  type    = bool
  default = false
}


variable "assign_generated_ipv6_cidr_block" {
  type    = bool
  default = false
}



variable "Tags" {
  type        = "map"
  description = "Tags"

  default = {
    Name        = ""
    Application = ""
    Environment = ""
    Tier        = ""
    Criticality = ""
    Requestor   = ""
    Support     = ""
    Client      = ""
    CostCenter  = ""
  }
}
