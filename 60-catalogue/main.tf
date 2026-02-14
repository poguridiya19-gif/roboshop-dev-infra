# create ec2 instance

resource "aws_instance" "catalogue" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.catalogue_sg_id.value]
  subnet_id              = local.private_subnet_id
  tags = merge (
    local.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-catalogue" #roboshop-dev-catalogue
    }
  )
}

# connect to instance through remote-exec provisioner through terraform_data

resource "terraform_data" "catalogue" {
  triggers_replace = [
    aws_instance.catalogue.id
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.catalogue.private_ip
  }
  # terraform copies this file to catalogue server
  provisioner "file" {
    source      = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/catalogue.sh" ,
      "sudo sh /tmp/catalogue.sh catalogue ${var.environment}"
    ]
  }
}

# stop the instance to take ami image
resource "aws_ec2_instance_state" "catalogue" {
  instance_id = aws_instance.catalogue.id
  state       = "stopped"
  depends_on  = [terraform_data.catalogue]
}
resource "aws_ami_from_instance" "catalogue" {
  name               = "${local.common_name_suffix}-catalogue-ami"
  source_instance_id = aws_instance.catalogue.id
  depends_on         = [ aws_ec2_instance_state.catalogue ]
  tags                   = merge (
    local.common_tags,
    {
        Name             = "${var.project_name}-${var.environment}-catalogue" #roboshop-dev-catalogue
    }
  )
}
# # create target group
# resource "aws_lb_target_group" "catalogue"{
#   name = "${local.common_name_suffix}-catalogue"
#   port = 8080
#   protocol = "HTTP"
#   vpc_id = local.vpc_id
#   deregistration_delay = 60 # waiting period before deleting the instance

#   health_check {
#     healthy_threshold = 2
#     interval = 10
#     matcher = "200-299"
#     path = "/health"
#     port = 8080
#     protocol = "HTTP"
#     timeout = 2
#     unhealthy_threshold = 2
#   }
# }
# # create launch template
# resource "aws_launch_template" "catalogue"{
#   name = "${local.common_name_suffix}-catalogue"
#   image_id = aws_ami_from_instance.catalogue.id
#   # instance_initiated_shutdown_behaviour = "terminate"
#   instance_type = "t3.micro"

#   vpc_security_group_ids = [local.catalogue_sg_id]

#   # tags attached to the instance
#   tags_specifications {
#     resource_type
#   }
# }
# # create auto scaling group
# # create auto scaling policy
# # create listener rule