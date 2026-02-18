# module "components" {
#     source = "git::https://github.com/poguridiya19-gif/terraform-roboshop-component.git"
#     component = var.component
#     rule_priority = var.rule_priority
# }

module "components" {
    for_each = var.component
    source = "git::https://github.com/daws-86s/terraform-roboshop-component.git?ref=main"
    component = each.key
    rule_priority = each.value.rule_priority
}