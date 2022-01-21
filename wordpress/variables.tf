variable "database_name" {
  type        = string
  description = "Name of the Wordpress DB"
}
variable "database_user_name" {
  type        = string
  description = "Name of the User of the Wordpress DB"
}

variable "ec2_instance_type" {
  default = "t2.micro"

}

variable "wordpress_ingress_ports" {
  description = "Wordpress ingress ports"
  type        = list(number)
  default     = [80, 443]
}

variable "wordpress_egress_ports" {
  type    = list(number)
  default = [0]
}

variable "nginx_port" {
    type = number
    description = "Port in wich run nginx"
    default = 80
  
}