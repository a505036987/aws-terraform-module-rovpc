provider "aws" {
  region = "eu-central-1"
}


module "module" {
  source = "github.com/a505036987/aws-terraform-module-rovpc/module"

  wssdev-vpc         = "10.158.96.0/20"
  aws_region         = "eu-central-1"
  public_sn_count    = 2
  private_sn_count   = 2
  workspace_sn_count = 2
}
