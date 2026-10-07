# test region
provider "aws" {
  region = var.region
}

# locals
locals {
  name = "eits-tf-aws-sqs-alarms"

  # set alarm thresholds
  alarm_metric_thresholds = {
    ApproximateAgeOfOldestMessage         = 20
    ApproximateNumberOfMessagesNotVisible = 0
    NumberOfMessagesSent                  = 0
  }
}

# create sns topic for alarms
module "sns_alarms" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-sns.git"

  name = local.name
  # disable_default_alarms = true

  tags = var.tags
}

# create source sns topic
module "sns" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-sns.git"

  name = "${local.name}-source"
  # disable_default_alarms = true

  tags = var.tags
}

# test module
module "sqs" {
  source = "./../.."

  name                       = local.name
  policy_allowed_source_arns = [module.sns.topic_arn]

  # add sns topic to send alarms
  alarm_sns_topics        = [module.sns_alarms.topic_arn]
  alarm_metric_thresholds = local.alarm_metric_thresholds

  tags = var.tags
}
