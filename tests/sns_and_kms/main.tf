# test region
provider "aws" {
  region = var.region
}

# locals
locals {
  name = "eits-tf-aws-sqs-kms"
}

# create key
module "kms_key" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-kms.git"

  description = "KMS key for SQS queue eits-tf-aws-sqs testing"

  tags = var.tags
}

# create two sns topics
module "sns" {
  count  = 2
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-sns.git"

  name = local.name

  tags = var.tags
}

# test module
module "sqs" {
  source = "./../.."

  name                       = local.name
  policy_allowed_source_arns = module.sns[*].topic_arn

  kms_master_key_id                 = module.kms_key.key_arn
  kms_data_key_reuse_period_seconds = 3600

  # test specific value
  receive_wait_time_seconds = 10

  tags = var.tags
}
