locals {
  registry_policies = {
    deny-public-network = "0fdf0491-d080-4575-b627-ad0e843cba0f"
    deny-admin-user     = "dc921057-6b28-4fbe-9b83-f7bec05db6c2"
    deny-anonymous-pull = "9f2dea28-e834-476c-99c5-3507b4728395"
    deny-export         = "524b0254-c285-4903-bee6-bb8126cde579"
    require-private-sku = "bd560fc0-3c69-498a-ae9f-aa8eb7de0e13"
  }
}

resource "azurerm_resource_group_policy_assignment" "registry" {
  for_each = local.registry_policies

  name                 = each.key
  resource_group_id    = azurerm_resource_group.this.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/${each.value}"

  parameters = jsonencode({
    effect = { value = "Deny" }
  })
}
