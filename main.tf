terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "azurerm" {
  subscription_id = local.subscription_id
  features {}
}

provider "databricks" {
  host = local.databricks_workspace_host
}

provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id
}

resource "azurerm_storage_account" "this" {
  name                     = "${local.prefix}menagedstorage"
  resource_group_name      = local.resource_group
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "metastore" {
  name                  = "metastore-terraform-menaged"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "databricks_metastore" "this" {
  provider      = databricks.accounts
  name          = "dbk-metastore"
  force_destroy = true
  region        = data.azurerm_resource_group.this.location
  storage_root  = "abfss://${azurerm_storage_container.metastore.name}@${azurerm_storage_account.this.name}.dfs.core.windows.net/"
}

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.accounts
  workspace_id = local.databricks_workspace_id
  metastore_id = databricks_metastore.this.id
}

resource "databricks_catalog" "db_prod" {
  name         = "db-prod"
  comment      = "Production catalog"
  metastore_id = databricks_metastore.this.id
}

resource "databricks_catalog" "db_dev" {
  name         = "db-dev"
  comment      = "Development catalog"
  metastore_id = databricks_metastore.this.id
}

resource "databricks_group" "analyst" {
  provider     = databricks.accounts
  display_name = "analyst"
}

resource "databricks_group" "tech_lead" {
  provider     = databricks.accounts
  display_name = "tech_lead"
}

resource "databricks_user" "analysts" {
  provider  = databricks.accounts
  for_each  = toset(var.analyst_users)
  user_name = each.value
}

resource "databricks_user" "tech_leads" {
  provider  = databricks.accounts
  for_each  = toset(var.tech_lead_users)
  user_name = each.value
}

resource "databricks_group_member" "analysts" {
  provider  = databricks.accounts
  for_each  = databricks_user.analysts
  group_id  = databricks_group.analyst.id
  member_id = each.value.id
}

resource "databricks_group_member" "tech_leads" {
  provider  = databricks.accounts
  for_each  = databricks_user.tech_leads
  group_id  = databricks_group.tech_lead.id
  member_id = each.value.id
}

resource "databricks_grants" "catalog_db_dev" {
  catalog = databricks_catalog.db_dev.name

  depends_on = [
    databricks_group.analyst,
    databricks_group.tech_lead
  ]

  grant {
    principal  = databricks_group.analyst.display_name
    privileges = ["USE CATALOG", "USE SCHEMA", "SELECT", "MODIFY"]
  }

  grant {
    principal  = databricks_group.tech_lead.display_name
    privileges = ["USE CATALOG", "USE SCHEMA", "SELECT", "MODIFY"]
  }
}

resource "databricks_grants" "catalog_db_prod" {
  catalog = databricks_catalog.db_prod.name

  depends_on = [
    databricks_group.analyst,
    databricks_group.tech_lead
  ]

  grant {
    principal  = databricks_group.analyst.display_name
    privileges = ["USE CATALOG", "USE SCHEMA", "SELECT"]
  }

  grant {
    principal  = databricks_group.tech_lead.display_name
    privileges = ["USE CATALOG", "USE SCHEMA", "SELECT", "MODIFY"]
  }
}

data "databricks_cluster_policy" "shared_compute" {
  name = "Shared Compute"
}

resource "databricks_cluster" "shared_compute_cluster" {
  cluster_name            = "Shared Compute Cluster"
  spark_version           = "15.4.x-scala2.12"
  node_type_id            = "Standard_DS3_v2"
  driver_node_type_id     = "Standard_DS3_v2"
  autotermination_minutes = 15

  autoscale {
    min_workers = 1
    max_workers = 4
  }

  runtime_engine = "STANDARD"

  custom_tags = {
    "ResourceClass" = "Standard"
  }

  policy_id = data.databricks_cluster_policy.shared_compute.id
}

resource "databricks_permissions" "cluster_usage" {
  cluster_id = databricks_cluster.shared_compute_cluster.id

  access_control {
    group_name       = databricks_group.analyst.display_name
    permission_level = "CAN_ATTACH_TO"
  }

  access_control {
    group_name       = databricks_group.tech_lead.display_name
    permission_level = "CAN_MANAGE"
  }

  depends_on = [
    databricks_cluster.shared_compute_cluster
  ]
}
