# test region
provider "aws" {
  region = var.region
}

# locals
locals {
  prefix = "custom-prefix-"
  name = "eits-tf-aws-sqs-dlq"
}

# crease source queue
module "sqs_source" {
  source = "./../.."
  
  name = "${local.name}-source"
  prefix = local.prefix
  tags = var.tags
}

# test module
module "sqs_dlq" {
  source = "./../.."

  prefix            = local.prefix
  name              = local.name
  dead_letter_queue = true

  dead_letter_queue_source = {
    dlqsource = {
      sourceQueueArn  = module.sqs_source.queue_arn
      sourceQueueUrl  = module.sqs_source.queue_url
      maxReceiveCount = 10
    }
  }

  tags = var.tags
}
