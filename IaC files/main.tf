# ============================================================
# main.tf — Provider configuration and remote backend
# Project: Azure Cost Visibility Dashboard
# Owner:   MOKCLOUD / mokenyujunior-tech
# ============================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote backend: stores terraform.tfstate in Azure Blob Storage
  # so every run (local or GitHub Actions) reads the same state.
  # This storage account is created manually ONCE in Section 3
  # of the walkthrough, before the first `terraform init`.
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatecvd0411"
    container_name       = "tfstate"
    key                  = "cost-visibility.terraform.tfstate"
  }
}

# Azure provider. Reads ARM_CLIENT_ID / ARM_CLIENT_SECRET /
# ARM_SUBSCRIPTION_ID / ARM_TENANT_ID environment variables
# automatically when running in GitHub Actions.
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
