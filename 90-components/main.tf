module "components" {
    source = "git::https://github.com/poguridiya19-gif/terraform-roboshop-component.git"
    component = var.component
    rule_priority = var.rule_priority
}
