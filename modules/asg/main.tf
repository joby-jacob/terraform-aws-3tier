data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter { name = "name" values = ["amzn2-ami-hvm-*-x86_64-gp2"] }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.name}-app" }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.name}-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_type         = "ELB"
  health_check_grace_period = 90

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arn]

  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}
