locals {
  name = "${var.project}-${var.environment}"
}

# -------- VPC (public/private subnets + NAT) --------
module "vpc" {
  source     = "./modules/vpc"
  name       = local.name
  cidr_block = var.vpc_cidr
  az_count   = var.az_count
}

# -------- Security Groups --------
module "security" {
  source = "./modules/security"
  name   = local.name

  vpc_id = module.vpc.vpc_id
}

# -------- Application Load Balancer --------
module "alb" {
  source        = "./modules/alb"
  name          = local.name
  vpc_id        = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id     = module.security.alb_sg_id
}

# -------- Auto Scaling Group (EC2) behind ALB --------
module "asg" {
  source = "./modules/asg"

  name              = local.name
  private_subnet_ids= module.vpc.private_subnet_ids
  instance_type     = var.instance_type

  target_group_arn  = module.alb.target_group_arn
  app_sg_id         = module.security.app_sg_id
  user_data         = <<-EOF
                      #!/bin/bash
                      yum update -y
                      amazon-linux-extras install nginx1 -y
                      echo "Hello from ${local.name} ($(hostname))" > /usr/share/nginx/html/index.html
                      systemctl enable nginx
                      systemctl start nginx
                      EOF

  desired_capacity  = var.desired_capacity
  min_size          = var.min_size
  max_size          = var.max_size
}
