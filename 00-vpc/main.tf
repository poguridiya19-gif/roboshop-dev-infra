module "vpc" {
    source = "git::https://github.com/poguridiya19-gif/terraform-aws-vpc?ref=main"

    #VPC
    vpc_cidr = var.vpc_cidr
    project_name = var.project_name
    environment = var.environment
    vpc_tags = var.vpc_tags

    # PUBLIC SUBNETS
    public_subnet_cidrs = var.public_subnet_cidrs

    # private subnets
    private_subnet_cidrs = var.private_subnet_cidrs

    # database subnets
    database_subnet_cidrs = var.database_subnet_cidrs

    is_peering_required = true

}

# data "aws_availabilty_zones" "available" {
#     state = "available"
# }