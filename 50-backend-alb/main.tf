resource "aws_lb" "backend_alb" {
  name               = "${local.common_name_suffix}-backend-alb" #roboshop-dev-backend-alb
  internal           = true
  load_balancer_type = "application"
  security_groups    = [local.backend_alb_sg_id]
  subnets            = local.private_subnet_ids

  enable_deletion_protection = false # prevents accidental deletion from ui

  tags = merge (
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-backend-alb" 
    }
  )
}

# # backend ALB listening on port number 80
# resource "aws_lb_listener" "backend_alb" {
#   load_balancer_arn = aws_lb.backend_alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "DIYA NANDA"
#       status_code  = "200"
#     }
#   }
# }

# Backend ALB listener on port 80
resource "aws_lb_listener" "backend_alb" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}
resource "aws_route53_record" "backend_alb" {
  zone_id = var.zone_id
  name = "*.backend-alb-${var.environment}.${var.domain_name}"
  type = "A"
  alias {
    # these are alb details ,not our domain details
    name = aws_lb.backend_alb.dns_name
    zone_id = aws_lb.backend_alb.zone_id
    evaluate_target_health = true
  }
}