resource "aws_instance" "mongodb" {
  ami          = local.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.mongodb_sg_id]
  subnet_id = local.database_subnet_ids
  tags = merge (
    local.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-mongodb" #roboshop-dev-mongodb
    }
  )
}

resource "terraform_data" "mongodb" {
  triggers_replace = [
    aws_instance.mongodb.id
  ]
  connection {
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
    host = aws_instance.mongodb.private_ip
  }
  # terraform copies this file to mongodb server
  provisioner "file" {
    source = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh" ,
      "sudo sh /tmp/bootstrap.sh"
    ]
  }
}

resource "aws_route53_record" "mongodb" {
  zone_id = var.zone_id
  name    = "mongodb-${var.environment}.${var.domain_name}" # mongodb-dev.poguri.fun
  type    = "A"
  ttl     = 1
  records = [aws_instance.mongodb.private_ip]
}















