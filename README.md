# Terraform Databricks and Azure Integration

This Terraform project automates the provisioning and configuration of Azure and Databricks resources, including managed storage, Unity Catalog metastore, user/group setup, and cluster permissions.

---

## Project Overview

This setup provisions:

- Azure Storage Account and Container for Unity Catalog.
- Unity Catalog Metastore and its assignment to a Databricks workspace.
- Two Databricks catalogs: `db-prod` and `db-dev`.
- Analyst and Tech Lead groups, along with their respective users and permissions.
- A shared compute cluster with group-based access control.

---

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- Azure Subscription and permissions to provision resources.
- Databricks Account with access to Unity Catalog features.

---

## Project Structure

```bash
.
├── main.tf                # Main Terraform configuration
├── variables.tf           # Input variables (analyst_users, tech_lead_users, databricks_account_id, etc.)
├── locals.tf              # Local values (e.g. subscription_id, workspace_id, resource group, etc.)
├── README.md              # Project documentation
```

## Configuration Details

### Providers

* azurerm for managing Azure resources

* databricks for workspace and account-level Databricks resources

### Azure Resources

* Storage Account with HNS (Hierarchical Namespace) enabled

* Storage Container used for the Unity Catalog Metastore

### Databricks Resources

* Metastore assigned to a specific workspace

* Catalogs:

    * db-prod: Production

    * db-dev: Development

* Groups:

    * analyst

    * tech_lead

* Users from variables are added to their respective groups

* Permissions:

    * analyst: read & write on db-dev, read-only on db-prod

    * tech_lead: full access on both catalogs

* Cluster: Shared compute with autoscaling and policy applied

* Cluster Permissions:

    * analyst: CAN_ATTACH_TO

    * tech_lead: CAN_MANAGE
