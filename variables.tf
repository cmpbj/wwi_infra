variable "databricks_resource_id" {
  description = "The Azure resource ID for the databricks workspace deployment."
  type        = string
}

locals {
  resource_regex            = "(?i)subscriptions/(.+)/resourceGroups/(.+)/providers/Microsoft.Databricks/workspaces/(.+)"
  subscription_id           = regex(local.resource_regex, var.databricks_resource_id)[0]
  resource_group            = regex(local.resource_regex, var.databricks_resource_id)[1]
  databricks_workspace_name = regex(local.resource_regex, var.databricks_resource_id)[2]
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url
  databricks_workspace_id   = data.azurerm_databricks_workspace.this.workspace_id
  prefix                    = replace(replace(lower(data.azurerm_resource_group.this.name), "rg", ""), "-", "")
}

variable "databricks_account_id" {
  description = "The account ID for the Databricks account (used in account-level operations)."
  type        = string
}

data "azurerm_resource_group" "this" {
  name = local.resource_group
}

data "azurerm_client_config" "current" {
}

data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group
}

variable "analyst_users" {
  type    = list(string)
  default = ["carlosmag.barreto_outlook.com#ext#@carlosmagbarretooutlook.onmicrosoft.com"]
}

variable "tech_lead_users" {
  type    = list(string)
  default = ["carlosmag.barreto@outlook.com"]
}

