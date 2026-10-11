# aws-control

Codifies the AWS Control Tower landing zone for Meridian Payments Ltd with Terraform: organizational units, Control Tower registration, and account vending with Account Factory for Terraform (AFT).

![Meridian Payment Ltd diagram](img/meridian-architecture.png)

## Repository layout

```
aws-control/
├── bootstrap/           # one-off: creates the S3 state bucket (local state)
├── live/
│   └── management/      # root module: OUs + Control Tower registration
└── modules/
    └── ous/             # one OU + its Control Tower baseline
```

Each folder under `live/` is a root module: run `terraform` from inside it. `modules/` are only ever called from a root module.

## Target organization

| OU | Parent | Accounts |
|---|---|---|
| Security | Root | Audit, Log Archive (created by Control Tower) |
| Infrastructure | Root | network, shared-service |
| Workloads | Root | — |
| Prod | Workloads | payment-prod, analytics-prod |
| NonProd | Workloads | payment-dev, analytics-dev |
| Sandbox | Root | sandbox-nick |
| Policy-Staging | Root | scp-test |
| Suspended | Root | — |
| AFT-Management | Root | aft-management |

| Account | ID | Role |
|---|---|---|
| Management | `790013274466` | Organizations, Control Tower, Terraform runs |
| Audit | `783495713938` | Created by Control Tower |
| Log Archive | `263953131739` | Created by Control Tower |
| aft-management | `255291985306` | Hosts the AFT pipelines |

Home region: `eu-west-2`. Governed regions: `eu-west-2`, `eu-west-1`, `eu-north-1`.

## Prerequisites

- Terraform >= 1.10 (S3-native state locking)
- AWS CLI v2 with an IAM Identity Center profile for the management account
- Credentials exported in every terminal that runs Terraform. The S3 backend does not read the provider block, so the profile must come from the environment:

  ```bash
  export AWS_PROFILE=nick
  export AWS_REGION=eu-west-2
  aws sso login            # when the session expires
  ```

- No static keys for the same profile in `~/.aws/credentials`. The Terraform AWS provider prefers them over SSO and fails with `InvalidClientTokenId` if they are stale.

## Steps

### 1. Create the organization and landing zone (console)

1. Created AWS Organizations from the management account.
2. Enabled Control Tower (landing zone 4.0, home region `eu-west-2`). This created:
   - the **Security** OU
   - the **Audit** and **Log Archive** accounts
   - IAM Identity Center, managed by Control Tower

These are owned by Control Tower and are not managed in this repo.

### 2. Bootstrap the state bucket

```bash
cd bootstrap
terraform init
terraform apply
```

Creates `meridian-payments-ltd-management-tfstate-bucket` (versioned, public access blocked). This root module uses local state, since the bucket can't hold its own state before it exists. `terraform.tfstate` here is gitignored; keep it safe.

### 3. Create and register the OUs

```bash
cd live/management
terraform init
terraform plan
terraform apply -parallelism=3
```

State: `s3://meridian-payments-ltd-management-tfstate-bucket/management/terraform.tfstate`.

For every OU, `modules/ous` creates:
- `aws_organizations_organizational_unit`
- `aws_controltower_baseline`, which registers the OU with Control Tower (`AWSControlTowerBaseline` v5.0, with the `IdentityCenterEnabledBaselineArn` parameter)

OU names live in `live/management/locals.tf`. Prod and NonProd `depends_on` the top-level OUs, because Control Tower only registers a child once its parent is registered.

`-parallelism=3` is required. Control Tower runs about three baseline operations at once and rejects the rest with `409 ConflictException`. If that happens, check that nothing is still in progress before re-applying:

```bash
aws controltower list-enabled-baselines \
  --query 'enabledBaselines[?contains(baselineIdentifier,`17BSJV3IGJ2QSGA2`)].[targetIdentifier,statusSummary.status]' \
  --output table
```

`SUCCEEDED` means registered, `UNDER_CHANGE` means wait, and `FAILED` means check the Control Tower console.

> OUs originally created in the console were deregistered in Control Tower and deleted in Organizations (children first) before the first apply, so Terraform owns all of them.

### 4. Grant the SSO role access to Account Factory

Control Tower only grants its own `AWSAdministratorAccess` permission set access to the Account Factory portfolio. To create accounts with the `AdministratorAccess` permission set, add it once:

Service Catalog → Portfolios → **AWS Control Tower Account Factory Portfolio** → Access → Grant access → Roles → `AWSReservedSSO_AdministratorAccess_*`

Without this, Account Factory fails with *"Your AWS IAM identity does not have access to the AWS Control Tower Account Factory portfolio"*.

### 5. Create the AFT management account

AFT has to live in its own account, which must exist before AFT is deployed. `AFT-Management` was added to `top_level_ous` and applied, then the account was vended through Account Factory:

```bash
aws servicecatalog provision-product \
  --product-id prod-jc7yxw7eh77ke \
  --provisioning-artifact-id pa-hliachkkfvpuq \
  --provisioned-product-name aft-management \
  --provisioning-parameters \
    Key=AccountName,Value=aft-management \
    Key=AccountEmail,Value=<new-unique-root-email> \
    Key=ManagedOrganizationalUnit,Value=AFT-Management \
    Key=SSOUserEmail,Value=<existing-identity-center-user-email> \
    Key=SSOUserFirstName,Value=<first> \
    Key=SSOUserLastName,Value=<last>
```

- `AccountEmail` is the new account's root email. It must never have been used by another AWS account (plus-addressing such as `name+aft@gmail.com` works).
- `SSOUserEmail` is the Identity Center user who gets admin access. An existing user is reused; an unknown email creates a new user.

Track progress until `AVAILABLE` (about 20–30 minutes):

```bash
aws servicecatalog scan-provisioned-products \
  --query 'ProvisionedProducts[?Name==`aft-management`].[Status,StatusMessage]' --output text
```

The account is created at the org root and moved into its OU partway through. Don't deploy AFT until it is `AVAILABLE` and shows as **Enrolled** in Control Tower.

### 6. Deploy AFT — *next*

- [ ] Request an Organizations account quota increase (currently 5, us-east-1 → Service Quotas)
- [ ] Create the AFT repos in the `Infra-bubble` GitHub org from the [AFT templates](https://github.com/aws-ia/terraform-aws-control_tower_account_factory/tree/main/sources/aft-customizations-repos):
  - `aft-account-request`
  - `aft-global-customizations`
  - `aft-account-customizations`
  - `aft-account-provisioning-customizations`
- [ ] `live/aft` root module calling `aws-ia/control_tower_account_factory/aws` (state key `aft/terraform.tfstate`, AFT VPC disabled)
- [ ] Approve the GitHub connection in the AFT account (Developer Tools → Connections)
- [ ] Global customization: baseline IAM role in every vended account
- [ ] Vend a test account with `account_tags`, verify, then close it

## Teardown

Delete in this order:

1. Close vended accounts (Organizations). Removing them from `aft-account-request` does not close them.
2. `terraform destroy` in `live/aft`
3. Close the AFT management account
4. Decommission the Control Tower landing zone
5. Delete the organization
