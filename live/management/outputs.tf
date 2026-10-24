output "controls_register" {
  description = "Optional Control Tower controls per OU, with the mechanism that implements each"
  value = {
    for ou, names in local.ou_controls : ou => {
      for c in names : c => "${local.controls[c].behavior} / ${local.controls[c].mechanism} - ${local.controls[c].name}"
    }
  }
}

output "custom_scps" {
  description = "Custom SCPs (PREVENTIVE / SCP, written in scps.tf) and where they are attached"
  value = {
    (module.scp_prod_deny_s3_create_bucket.id) = "PREVENTIVE / custom SCP - scp-prod-deny-s3-create-bucket -> Prod"
  }
}
