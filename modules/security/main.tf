# ALB Security Group: allow 80 from world
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB ingress 80"
  vpc_id      = var.vpc_id

  ingress { from_port = 80 to_port = 80 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0  to_port = 0  protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = { Name = "${var.name}-alb-sg" }
}

# App Security Group: allow 80 only from ALB SG
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "EC2 ingress from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb.id]
    description              = "From ALB"
  }

  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }

  tags = { Name = "${var.name}-app-sg" }
}

output "alb_sg_id" { value = aws_security_group.alb.id }
output "app_sg_id" { value = aws_security_group.app.id }
