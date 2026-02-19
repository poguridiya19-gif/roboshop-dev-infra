resource "aws_instance" "openvpn" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.openvpn_sg_id]
    subnet_id = local.public_subnet_id
    # user_data = file("vpn.sh")
    
    tags = merge (
        local.common_tags,
        {
            Name = "${var.project_name}-${var.environment}-openvpn"
        }
    )
}