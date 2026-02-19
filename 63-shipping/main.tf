# create ec2 instance

resource "aws_instance" "shipping" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.shipping_sg_id]
  subnet_id              = local.private_subnet_id
  tags = merge (
    local.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-shipping" #roboshop-dev-shipping
    }
  )
}

# connect to instance through remote-exec provisioner through terraform_data

resource "terraform_data" "shipping" {
  triggers_replace = [
    aws_instance.shipping.id
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.shipping.private_ip
  }
  # terraform copies this file to shipping server
  provisioner "file" {
    source      = "shipping.sh"
    destination = "/tmp/shipping.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/shipping.sh" ,
      "sudo sh /tmp/shipping.sh shipping ${var.environment}"
    ]
  }
}

# stop the instance to take ami image
resource "aws_ec2_instance_state" "shipping" {
  instance_id = aws_instance.shipping.id
  state       = "stopped"
  depends_on  = [terraform_data.shipping]
}

resource "aws_ami_from_instance" "shipping" {
  name               = "${local.common_name_suffix}-shipping-ami"
  source_instance_id = aws_instance.shipping.id
  depends_on         = [ aws_ec2_instance_state.shipping ]
  tags                   = merge (
    local.common_tags,
    {
        Name             = "${var.project_name}-${var.environment}-shipping" #roboshop-dev-shipping
    }
  )
}

# create target group
resource "aws_lb_target_group" "shipping"{
  name = "${local.common_name_suffix}-shipping"
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
resource "aws_launch_template" "shipping"{
  name = "${local.common_name_suffix}-shipping"
  image_id = aws_ami_from_instance.shipping.id

  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"

  vpc_security_group_ids = [local.shipping_sg_id]

  # when we run terraform apply again, a new version will be created with new AMI ID
  update_default_version = true

  # tags attached to the instance
  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-shipping"
      }
    )
  }
  # tags attached to the volume created by instance
  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-shipping"
      }
    )
  } 
  # tags attached to the launch template
  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-shipping"
    }
  )
}

# create auto scaling group
resource "aws_autoscaling_group" "shipping" {
  name  = "${local.common_name_suffix}-shipping"
  max_size = 10
  min_size = 1
  health_check_grace_period = 100
  health_check_type = "ELB"
  desired_capacity = 1
  force_delete = false
  launch_template {
    id = aws_launch_template.shipping.id
    version = aws_launch_template.shipping.latest_version
  }
  vpc_zone_identifier = local.private_subnet_ids
  target_group_arns = [aws_lb_target_group.shipping.arn]

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
        Name = "${local.common_name_suffix}-shipping"
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
resource "aws_autoscaling_policy" "shipping" {
  autoscaling_group_name = aws_autoscaling_group.shipping.name
  name = "${local.common_name_suffix}-shipping"
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }
}

# create listener rule
resource "aws_lb_listener_rule" "shipping" {
  listener_arn = local.backend_alb_listener_arn
  priority = 10
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.shipping.arn
  }
  condition {
    host_header {
      values = ["shipping.backend-alb-${var.environment}.${var.domain_name}"]
    }
  }
}

resource "terraform_data" "catalogue_local" {
  triggers_replace = [
    aws_instance.shipping.id
  ]
  
  depends_on = [aws_autoscaling_policy.shipping]
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.shipping.id}"
  }
}