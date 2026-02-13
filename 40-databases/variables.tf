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
    default = "Z09362922S2ZXJ8DP3JCV"
}

variable "domain_name"{
    default = "poguri.fun"
}