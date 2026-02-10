variable "project_name" {
    default = "roboshop"
}

variable "environment" {
    default = "dev"
}

variable "sg_names"{
    default = [
        # databases
        "mongodb","redis","rabbitmq","mysql",
        # backend
        "catalogue","cart","user","shipping","payment",
        # frontend
        "frontend",
        # bastion
        "bastion",
        # frontend load balancer
        "frontend_alb",
        # backend alb
        "backend_alb"
    ]
}

variable "zone_id"{
    default = "Z0948150OFPSYTNVYZOY"
}

variable "domain_name"{
    default = "poguri.fun"
}