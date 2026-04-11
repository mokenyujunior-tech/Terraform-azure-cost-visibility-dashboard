# ============================================================
# terraform.tfvars
# ============================================================
# Copy this file to terraform.tfvars and fill in your own
# values. terraform.tfvars is gitignored so it never gets
# committed to GitHub.
#
# In GitHub Actions, Terraform reads these same values from
# TF_VAR_* environment variables that the pipeline sets from
# GitHub Secrets. You do not need terraform.tfvars for the
# pipeline to work — only for local runs from your laptop.
# ============================================================

subscription_id = "ec289c8e-4873-4660-a368-35309d8ca713"
owner_email     = "mokenyukezongwe@outlook.com"

# Optional overrides:
# location              = "canadacentral"
# resource_group_name   = "rg-cost-visibility"
# project_short_name    = "cvd"
# monthly_budget_amount = 200
# weekly_report_cron    = "0 0 8 * * 1"
