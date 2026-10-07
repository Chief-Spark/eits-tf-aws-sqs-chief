# test region
provider "aws" {
  region = var.region
}

# locals
locals {
  name = "eits-tf-aws-sqs-external-policy"
}

# get account id
data "aws_caller_identity" "current" {}

# create sns topic
module "sns" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-sns.git"

  name = local.name
  
  tags = var.tags
}

# create policy document
# due to the way terraform handles (or doesnt) circular references we need to
# build the fully formed ARN values rather than referencing the module outputs here
# it is recommended to use the `policy_allowed_source_arns` module argument if possible instead
data "aws_iam_policy_document" "this" {
  policy_id = "SQSQueueSendMessage"

  statement {
    sid     = "SQSQueueSendMessage"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      "arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:*${local.name}-sqs-queue"
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:*${local.name}-sns-topic"
      ]
    }
  }
}

# test module
module "sqs" {
  source = "./../.."

  name        = local.name
  policy_json = data.aws_iam_policy_document.this.json

  tags = var.tags
}
