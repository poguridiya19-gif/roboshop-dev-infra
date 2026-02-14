locals {
  common_name_suffix = "${var.project_name}-${var.environment}" # roboshop-dev
  ami_id = data.aws_ami.joindevops.id
  catalogue_sg_id = data.aws_ssm_parameter.catalogue_sg_id
  # vpc_id = data.aws_ssm_parameter.vpc_id
  private_subnet_id = split("," , data.aws_ssm_parameter.private_subnet_ids.value)[0]
  common_tags = {
    Project = var.project_name
    Environment = var.environment
    Terraform = "true"
  }
}
