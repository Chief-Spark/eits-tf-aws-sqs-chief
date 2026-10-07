locals {
  prefix = var.prefix != null ? var.prefix : module.eits_ce_common.prefix
  name = format("%s-%s-sqs-queue%s", local.prefix, var.name, var.fifo_queue ? ".fifo" : "")
  tags = merge(var.tags, module.eits_ce_common.tags)

  # check if the environment is prod
  has_prod_tag = lookup(merge(data.aws_default_tags.this.tags, var.tags), "Environment", "") == "prd"
}

# get provider tags
data "aws_default_tags" "this" {}

module "eits_ce_common" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-ce-common.git?ref=v1"

  module_repo = "eits-tf-aws-sqs"
  tags        = var.tags
}

resource "aws_sqs_queue" "this" {
  name                       = local.name
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds != null ? var.receive_wait_time_seconds : local.has_prod_tag ? 0 : 20
  visibility_timeout_seconds = var.visibility_timeout_seconds
  deduplication_scope        = var.deduplication_scope

  # encryption config
  sqs_managed_sse_enabled           = var.kms_master_key_id == null ? true : null
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id == null ? null : var.kms_data_key_reuse_period_seconds

  # fifo topic config
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_content_based_deduplication && var.fifo_queue ? true : null
  fifo_throughput_limit       = var.fifo_queue ? var.fifo_throughput_limit : null

  tags = local.tags
}

data "aws_iam_policy_document" "this" {
  count = length(var.policy_json) == 0 && length(var.policy_allowed_source_arns) > 0 ? 1 : 0

  policy_id = "SQSSendMessage"
  statement {
    sid       = "AllowSQSSendMessage"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    dynamic "condition" {
      for_each = length(var.policy_allowed_source_arns) > 0 ? ["_enable"] : []
      content {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = var.policy_allowed_source_arns
      }
    }
  }
}

data "aws_iam_policy_document" "enable_secure_transport_policy" {
  count = var.enable_secure_transport_policy ? 1 : 0

  statement {
    sid       = "DenyNonSSLMessageRequests"
    effect    = "Deny"
    actions   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"]
    resources = [aws_sqs_queue.this.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  count = var.enable_secure_transport_policy || length(var.policy_json) > 0 || length(var.policy_allowed_source_arns) > 0 ? 1 : 0

  queue_url = aws_sqs_queue.this.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      try(jsondecode(data.aws_iam_policy_document.enable_secure_transport_policy[0].json).Statement, []),
      length(var.policy_json) > 0 ? try(tolist(jsondecode(var.policy_json).Statement), []) : try(tolist(jsondecode(data.aws_iam_policy_document.this[0].json).Statement), [])
    )
  })
}

# dead-letter queue redrive policy
resource "aws_sqs_queue_redrive_policy" "dlq" {
  for_each = var.dead_letter_queue_source

  queue_url = each.value.sourceQueueUrl
  redrive_policy = jsonencode(
    {
      deadLetterTargetArn = aws_sqs_queue.this.arn
      maxReceiveCount     = each.value.maxReceiveCount
    }
  )
}

# dead-letter queue allow policy
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count = var.dead_letter_queue && length(var.dead_letter_queue_source) > 0 ? 1 : 0

  queue_url = aws_sqs_queue.this.url
  redrive_allow_policy = jsonencode(
    {
      redrivePermission = "byQueue",
      sourceQueueArns   = [for source in var.dead_letter_queue_source : source.sourceQueueArn]
    }
  )
}
