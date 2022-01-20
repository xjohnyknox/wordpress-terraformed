data "aws_availability_zones" "zones" {
    state = "available"
  
}

data "aws_subnet_ids" "subnets" {
  vpc_id = var.vpc_id
}