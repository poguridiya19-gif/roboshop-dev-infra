variable "rule_priority" {
    default = 10
} 

variable "component" {
    default = {
        catalogue = {
            rule_priority = 10
        }
        user = {
            rule_priority = 10
        }
        cart = {
            rule_priority = 10
        }
        shipping = {
            rule_priority = 10
        }
        payment = {
            rule_priority = 10
        }
        frontend = {
            rule_priority = 10
        }
    }
}

