variable "project"     { type = string  default = "jj-3tier" }
variable "environment" { type = string  description = "dev|stage|prod" }
variable "region"      { type = string  default = "ap-south-1" } # Mumbai

variable "vpc_cidr"    { type = string  default = "10.0.0.0/16" }
variable "az_count"    { type = number  default = 2 } # 2 AZs

# Instance settings for ASG
variable "instance_type" { type = string default = "t3.micro" }
variable "desired_capacity" { type = number default = 2 }
variable "min_size" { type = number default = 2 }
variable "max_size" { type = number default = 4 }
