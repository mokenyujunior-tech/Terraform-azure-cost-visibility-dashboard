# Azure Cost Visibility Dashboard — Terraform & GitHub Actions

> **Infrastructure as Code portfolio project** — deploys a complete Azure cost monitoring and alerting stack using Terraform, with a CI/CD pipeline built on GitHub Actions and PowerShell.

This project provisions an end-to-end cost visibility solution for an Azure subscription: budgets with multi-threshold alerts, a Logic App that emails on budget breaches, a Python Function App that runs a weekly cost report, an Azure Monitor workbook for dashboards, and Log Analytics for telemetry. Every resource is defined in Terraform, every deployment is triggered by `git push`, and all secrets live in GitHub Secrets.

---

## 🏗️ Architecture

```
┌──────────────┐       git push        ┌─────────────────────┐
│  Developer   ├──────────────────────▶│  GitHub Repository  │
│  (Windows +  │                       │   (main branch)     │
│  PowerShell) │                       └──────────┬──────────┘
└──────────────┘                                  │
                                                  │ triggers
                                                  ▼
                                       ┌─────────────────────┐
                                       │  GitHub Actions     │
                                       │  Pipeline (pwsh)    │
                                       │                     │
                                       │  1. Validate        │
                                       │  2. Plan            │
                                       │  3. Apply           │
                                       └──────────┬──────────┘
                                                  │
                                       Service Principal auth
                                       (ARM_* env vars)
                                                  │
                                                  ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │                    Azure Subscription                           │
   │                                                                 │
   │   ┌──────────────────────┐   ┌───────────────────────────────┐  │
   │   │  rg-terraform-state  │   │       rg-cost-visibility      │  │
   │   │                      │   │                               │  │
   │   │ sttfstatecvd0411     │   │  ┌─────────┐   ┌──────────┐   │  │
   │   │  └── tfstate/        │   │  │ Budget  │──▶│  Action  │   │  │
   │   │       cost-visibi    │   │  │ ($200)  │   │  Group   │   │  │
   │   │       lity.tfstate   │   │  └─────────┘   └─────┬────┘   │  │
   │   └──────────────────────┘   │                      │        │  │
   │                              │                      ▼        │  │
   │                              │                 ┌─────────┐   │  │
   │                              │                 │ Logic   │   │  │
   │                              │                 │ App     │──▶ email
   │                              │                 └─────────┘   │  │
   │                              │                                │  │
   │                              │  ┌──────────┐   ┌──────────┐   │  │
   │                              │  │ Function │──▶│  Cost    │   │  │
   │                              │  │ App (Py) │   │  Mgmt    │   │  │
   │                              │  └────┬─────┘   │  API     │   │  │
   │                              │       │         └──────────┘   │  │
   │                              │       ▼                        │  │
   │                              │  ┌──────────┐                  │  │
   │                              │  │Log Analyt│                  │  │
   │                              │  │+ AppInsig│                  │  │
   │                              │  └──────────┘                  │  │
   │                              └───────────────────────────────┘  │
   └─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Resources Deployed

| Resource | Name pattern | Purpose | costcategory tag |
|---|---|---|---|
| Resource group | `rg-cost-visibility` | Container for every resource in this project | Automation |
| Log Analytics Workspace | `log-cvd-<suffix>` | Collects telemetry from App Insights and the Function App | Monitoring |
| Application Insights | `appi-cvd-<suffix>` | Traces and logs for the Function App (wired to Log Analytics) | Monitoring |
| Storage Account | `stcvd<suffix>` | Function App coordination + holds zipped Python code | Storage |
| App Service Plan (Y1) | `asp-cvd-<suffix>` | Linux Consumption plan for the Function App | Automation |
| Linux Function App | `func-cvd-<suffix>` | Python 3.11 weekly cost reporter with system-assigned MI | Automation |
| Office 365 API Connection | `api-office365-cvd-<suffix>` | Used by the Logic App to send email | Automation |
| Logic App (via ARM template) | `la-cost-alert-emailer-cvd-<suffix>` | Receives alerts and sends email | Automation |
| Monitor Action Group | `ag-cost-alerts-cvd-<suffix>` | Fires the Logic App on budget thresholds | Automation |
| Consumption Budget | `monthly-cost-budget-200` | $200 CAD monthly budget with 50/75/90/100% thresholds | (subscription-scoped) |
| Monitor Workbook | Cost Visibility Dashboard | KQL-based visual breakdown of costs by tag | Monitoring |
| Role Assignment | (Cost Management Reader) | Grants the Function App MI access to Cost Management APIs | (subscription-scoped) |

---

## 🛠️ Technology Stack

- **IaC:** Terraform 1.7.5+ with AzureRM provider `~> 3.110`
- **State Backend:** Azure Blob Storage (`sttfstatecvd0411`, container `tfstate`)
- **CI/CD:** GitHub Actions with PowerShell Core (`pwsh`)
- **Authentication:** Service Principal with Contributor role
- **Function Runtime:** Python 3.11 on Linux Consumption (Y1)
- **Alerting:** Azure Monitor → Action Group → Logic App → Office 365 Outlook
- **Monitoring:** Log Analytics Workspace + Application Insights (workspace-based)

---

## 🔐 Security Architecture

### Authentication
Terraform authenticates to Azure using a **Service Principal** with the **Contributor** role scoped to the subscription, following the principle of least privilege from the AZ-104 Identities & Governance module.

```
GitHub Secrets (encrypted vault)
├── ARM_CLIENT_ID           → Service Principal identity
├── ARM_CLIENT_SECRET       → Service Principal credential
├── ARM_SUBSCRIPTION_ID     → Target Azure subscription
├── ARM_TENANT_ID           → Microsoft Entra ID tenant
└── TF_VAR_OWNER_EMAIL      → Email for alerts (marked sensitive)
```

Secrets are injected as environment variables at pipeline runtime — **never written to any file**, never committed to Git.

### State Management
Terraform state lives in **Azure Blob Storage**, shared between local and pipeline runs. The state storage account is provisioned manually **once** before any `terraform init` runs, because Terraform needs the backend to exist before it can initialize. See the walkthrough Section 3.

### Tagging Governance
Every resource is tagged with `project`, `environment`, `deployment`, `owner`, `department`, and a resource-specific `costcategory`. The Function App reads the `costcategory` tag via Cost Management queries to produce the weekly breakdown.

---

## 🚀 Deployment Prerequisites

- [ ] Azure subscription
- [ ] GitHub account with a new public repo
- [ ] PowerShell 7+ installed (`winget install Microsoft.PowerShell`)
- [ ] Azure CLI installed (`winget install Microsoft.AzureCLI`)
- [ ] Terraform installed (`winget install Hashicorp.Terraform`)
- [ ] Git installed (`winget install Git.Git`)

---

## 📖 How to Deploy

### Step 1 — Create Remote State Storage (one-time)

```powershell
$stateRG      = "rg-terraform-state"
$stateAccount = "sttfstatecvd0411"
$location     = "canadacentral"

az group create --name $stateRG --location $location
az storage account create `
  --name $stateAccount `
  --resource-group $stateRG `
  --location $location `
  --sku Standard_LRS `
  --min-tls-version TLS1_2
az storage container create `
  --name tfstate `
  --account-name $stateAccount
```

### Step 2 — Create Service Principal (one-time)

```powershell
$subscriptionId = (az account show --query id -o tsv)

az ad sp create-for-rbac `
  --name sp-terraform-cost-visibility `
  --role Contributor `
  --scopes /subscriptions/$subscriptionId
```

Copy the output. You'll need `appId`, `password`, `tenant`, and `$subscriptionId` in Step 3.

### Step 3 — Add GitHub Secrets

Go to your repo → **Settings → Secrets and variables → Actions** and add six secrets:

| Secret name | Value |
|---|---|
| `ARM_CLIENT_ID` | `appId` from Step 2 |
| `ARM_CLIENT_SECRET` | `password` from Step 2 |
| `ARM_SUBSCRIPTION_ID` | `$subscriptionId` from Step 2 |
| `ARM_TENANT_ID` | `tenant` from Step 2 |
| `TF_VAR_OWNER_EMAIL` | Your email address |

(The pipeline passes `ARM_SUBSCRIPTION_ID` through as `TF_VAR_subscription_id` automatically.)

### Step 4 — Clone and Push

```powershell
git clone https://github.com/<your-user>/azure-cost-visibility-terraform.git
cd azure-cost-visibility-terraform
# Copy all files from this project here
git add .
git commit -m "Initial deployment"
git push origin main
```

### Step 5 — Watch the Pipeline

Go to the **Actions** tab in your GitHub repo. You should see "Deploy Cost Visibility Dashboard" running. It takes about 5-8 minutes on the first run (Oryx has to build the Python dependencies on the Function App).

### Step 6 — Post-Apply Manual Steps

After the pipeline succeeds:

1. **Authorize the Office 365 connection** (one-time human click):
   - Portal → `rg-cost-visibility` → `api-office365-cvd-<suffix>`
   - Edit API connection → Authorize → sign in with the email
   - Save

2. **Test the Function App**:
   - Portal → `func-cvd-<suffix>` → Functions → `WeeklyCostReport`
   - Code + Test → Test/Run
   - Check your inbox for the email

---

## 💣 How to Destroy

Two ways:

**Option A — Via the pipeline (recommended):**
1. Go to GitHub → Actions → "Deploy Cost Visibility Dashboard"
2. Click "Run workflow" (top right)
3. Pick `destroy` from the dropdown
4. Click "Run workflow"

**Option B — From your laptop:**
```powershell
terraform init
terraform destroy
```

Both options leave `rg-terraform-state` and `sttfstatecvd0411` alone — the state storage is intentionally outside Terraform's management so it survives destroys.

---

## 📚 AZ-104 Module Mapping

| AZ-104 Module | How this project demonstrates it |
|---|---|
| Manage Azure identities and governance | Service Principal with least-privilege Contributor role, managed identity for the Function App, Cost Management Reader RBAC assignment |
| Implement and manage storage | Storage Account with TLS 1.2, private containers, SAS tokens, LRS replication |
| Deploy and manage Azure compute | Linux Consumption Function App, App Service Plan (Y1) |
| Implement and manage virtual networking | _Covered in the sibling lb-demo-tf project_ |
| Monitor and maintain Azure resources | Log Analytics, Application Insights, Monitor Action Group, Monitor Workbook, Consumption Budget with multi-threshold notifications |

---

## 🧠 What I Learned Building This

- **State backend must exist before `terraform init`** — chicken-and-egg circular dependency solved by bootstrapping the state storage manually once
- **ARM template deployment outputs are flattened** by Terraform — you access `callbackUrl` directly, not `callbackUrl.value`
- **Application Insights auto-attaches a workspace** in most Azure regions now — the only clean fix is to declare a Log Analytics Workspace explicitly and pass its ID via `workspace_id`
- **Python Azure Functions require Linux Consumption** — Windows Consumption only supports .NET, Node, PowerShell, and Java
- **Tags aren't retroactive** — Cost Management can only categorise costs by tags that existed at the time of the usage record, so enforcing tags at creation time (via Terraform or Azure Policy) is the only way to get clean historical data
- **`shell: pwsh` on every job** in GitHub Actions keeps the pipeline consistent with local Windows development

---

## 📁 Repository Structure

```
cost-visibility-dashboard/
├── main.tf                      # Provider + remote backend
├── variables.tf                 # Input variables
├── terraform.tfvars     # Template for local values
├── resource_group.tf            # Main RG + random suffix
├── log_analytics.tf             # Log Analytics Workspace
├── application_insights.tf      # Wired to the workspace
├── storage.tf                   # Function App storage + code blob
├── function_app.tf              # Linux Python Function App
├── logic_app.tf                 # ARM template deployment + API connection
├── action_group.tf              # Monitor Action Group
├── budget.tf                    # Consumption Budget with 4 notifications
├── workbook.tf                  # Monitor Workbook for the dashboard
├── role_assignment.tf           # Cost Management Reader for MI
├── outputs.tf                   # Post-apply instructions
├── .gitignore                   # Excludes state, tfvars, build artefacts
├── README.md                    # This file
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD pipeline
├── function_code/
│   ├── function_app.py          # Python v2 model timer-triggered function
│   ├── requirements.txt         # Azure SDK dependencies
│   └── host.json                # Functions host config
└── workbook/
    └── cost_overview.json       # KQL workbook definition
```

---

## 🙋 Author

**MK (MOKCLOUD)** — Cloud Computing and Systems Administration post-graduate student at George Brown College, Toronto. Studying AZ-104. Reach me at [mokenyujunior-tech on GitHub](https://github.com/mokenyujunior-tech).
