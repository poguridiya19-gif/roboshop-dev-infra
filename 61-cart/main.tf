# create ec2 instance

resource "aws_instance" "cart" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.cart_sg_id]
  subnet_id              = local.private_subnet_id
  tags = merge (
    local.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-cart" #roboshop-dev-cart
    }
  )
}

# connect to instance through remote-exec provisioner through terraform_data

resource "terraform_data" "cart" {
  triggers_replace = [
    aws_instance.cart.id
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.cart.private_ip
  }
  # terraform copies this file to cart server
  provisioner "file" {
    source      = "cart.sh"
    destination = "/tmp/cart.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/cart.sh" ,
      "sudo sh /tmp/cart.sh cart ${var.environment}"
    ]
  }
}

# stop the instance to take ami image
resource "aws_ec2_instance_state" "cart" {
  instance_id = aws_instance.cart.id
  state       = "stopped"
  depends_on  = [terraform_data.cart]
}

resource "aws_ami_from_instance" "cart" {
  name               = "${local.common_name_suffix}-cart-ami"
  source_instance_id = aws_instance.cart.id
  depends_on         = [ aws_ec2_instance_state.cart ]
  tags                   = merge (
    local.common_tags,
    {
        Name             = "${var.project_name}-${var.environment}-cart" #roboshop-dev-cart
    }
  )
}

# create target group
resource "aws_lb_target_group" "cart"{
  name = "${local.common_name_suffix}-cart"
  port = 8080
  protocol = "HTTP"
  vpc_id = local.vpc_id
  deregistration_delay = 60 # waiting period before deleting the instance

  health_check {
    healthy_threshold = 2
    interval = 10
    matcher = "200-299"
    path = "/health"
    port = 8080
    protocol = "HTTP"
    timeout = 2
    unhealthy_threshold = 2
  }
}

# create launch template
resource "aws_launch_template" "cart"{
  name = "${local.common_name_suffix}-cart"
  image_id = aws_ami_from_instance.cart.id

  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"

  vpc_security_group_ids = [local.cart_sg_id]

  # when we run terraform apply again, a new version will be created with new AMI ID
  update_default_version = true

  # tags attached to the instance
  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-cart"
      }
    )
  }
  # tags attached to the volume created by instance
  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-cart"
      }
    )
  } 
  # tags attached to the launch template
  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-cart"
    }
  )
}

# create auto scaling group
resource "aws_autoscaling_group" "cart" {
  name  = "${local.common_name_suffix}-cart"
  max_size = 10
  min_size = 1
  health_check_grace_period = 100
  health_check_type = "ELB"
  desired_capacity = 1
  force_delete = false
  launch_template {
    id = aws_launch_template.cart.id
    version = aws_launch_template.cart.latest_version
  }
  vpc_zone_identifier = local.private_subnet_ids
  target_group_arns = [aws_lb_target_group.cart.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50 # atleast 50% of the instance should be up and running 
    }
    # triggers = ["launch_template"]
  }

  dynamic "tag" { # we will get the iterator with name as tag
    for_each = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-cart"
      }
    )
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
   }
  timeouts {
    delete = "15m"
  }
}

# create auto scaling policy
resource "aws_autoscaling_policy" "cart" {
  autoscaling_group_name = aws_autoscaling_group.cart.name
  name = "${local.common_name_suffix}-cart"
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }
}

# create listener rule
resource "aws_lb_listener_rule" "cart" {
  listener_arn = local.backend_alb_listener_arn
  priority = 20
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.cart.arn
  }
  condition {
    host_header {
      values = ["cart.backend-alb-${var.environment}.${var.domain_name}"]
    }
  }
}

resource "terraform_data" "cart_local" {
  triggers_replace = [
    aws_instance.cart.id
  ]
  
  depends_on = [aws_autoscaling_policy.cart]
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.cart.id}"
  }
}