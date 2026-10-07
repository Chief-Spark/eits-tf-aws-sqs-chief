variable "dead_letter_queue" {
  type        = bool
  default     = false
  description = "Whether or not to create the queue as a dead-letter queue with associated redrive policy. See [AWS Docs](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) for more details"
}

variable "dead_letter_queue_source" {
  type = map(object({
    sourceQueueArn  = string
    sourceQueueUrl  = string
    maxReceiveCount = optional(number, 5)
  }))
  default     = {}
  description = "Configuration for a dead-letter queue. See README.md for more details. Required if `dead_letter_queue` is `true`"
}

variable "deduplication_scope" {
  type        = string
  default     = null
  description = "Specifies whether message deduplication occurs at the message group or queue level. Valid values are `messageGroup` and `queue` (default)"
}

variable "delay_seconds" {
  type        = number
  default     = 0
  description = "The time in seconds that the delivery of messages in the queue will be delayed. A number from 0 seconds to 900 (15 minutes)"

  validation {
    condition = (
      var.delay_seconds >= 0 && var.delay_seconds <= 900
    )
    error_message = "delay_seconds must be between 0 and 900 seconds, inclusive."
  }
}

variable "enable_secure_transport_policy" {
  type        = bool
  default     = true
  description = "Set to `true` to enforce the use of secure transport for sending messages to the SQS queue."
}

variable "fifo_content_based_deduplication" {
  type        = bool
  default     = false
  description = "Enables content-based deduplication for FIFO queues. Only applicable if `fifo_queue` is `true"
}

variable "fifo_queue" {
  type        = bool
  default     = false
  description = "Whether or not to create the queue as FIFO (first-in-first-out), will add .fifo name suffix automatically"
}

variable "fifo_throughput_limit" {
  type        = string
  default     = "perQueue"
  description = "Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are `perQueue` (default) and `perMessageGroupId`. Only applicable if `fifo_queue` is `true`"
}

variable "kms_data_key_reuse_period_seconds" {
  type        = number
  default     = 300
  description = "The time in seconds for which SQS can reuse a data key to encrypt or decrypt messages before calling KMS again. A number from 60 (1 min) to 86400 (24 hours). Only applicable if `kms_master_key_id` is used"

  validation {
    condition = (
      var.kms_data_key_reuse_period_seconds >= 60 && var.kms_data_key_reuse_period_seconds <= 86400
    )
    error_message = "kms_data_key_reuse_period_seconds must be between 60 and 86400 seconds, inclusive."
  }
}

variable "kms_master_key_id" {
  type        = string
  default     = null
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK. If supplied, will change encryption from [SSE-SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sqs-sse-queue.html) to [SSE-KMS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sse-existing-queue.html)"
}

variable "max_message_size" {
  type        = number
  default     = 262144
  description = "The limit of how many bytes a message can contain before SQS rejects it. A number from 1024 (1 KiB) to 262144 (256 KiB)"

  validation {
    condition = (
      var.max_message_size >= 1024 && var.max_message_size <= 262144
    )
    error_message = "max_message_size must be between 1024 and 262144 bytes, inclusive."
  }

}

variable "message_retention_seconds" {
  type        = number
  default     = 345600
  description = "The time in seconds SQS retains a message. A number from 60 (1 minute) to 1209600 (14 days)."

  validation {
    condition = (
      var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    )
    error_message = "message_retention_seconds must be between 60 and 1209600 seconds, inclusive."
  }
}

variable "name" {
  type        = string
  description = "The name of the queue. The actual resource name will be created as `{account_naming_construct}-{name}-sqs-queue` in accordance with the [EEC Cloud Naming Conventions](https://experian.atlassian.net/wiki/x/XwH3E). If `fifo_queue` is set to `true` a .fifo suffix will be automatically added"

  validation {
    condition = (
      can(regex("^[a-zA-Z0-9-_]+$", var.name)) || var.name == null
    )
    error_message = "The name variable must have alphanumeric, underscore and hyphen characters"
  }
}

variable "policy_json" {
  type        = string
  default     = ""
  description = "The fully-formed AWS policy as JSON, if required. Will override anything specified in `policy_allowed_source_arns`"
}

variable "policy_allowed_source_arns" {
  type        = list(string)
  default     = []
  description = "Source ARNs that will have permission to send messages from the SQS queue. Used when `policy_json` is not supplied"
}

variable "receive_wait_time_seconds" {
  type        = number
  default     = null
  description = "The time in seconds for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. A number from 0 to 20 (seconds). If left at the default `null`, then `0` will be automatically set for resources with an 'Environment' tag of value 'prd', and `20` for other environments. This is a cost-saving measure"

  validation {
    condition = (
      var.receive_wait_time_seconds == null ? true : (var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20)
    )
    error_message = "receive_wait_time_seconds must be between 0 and 20 seconds, inclusive."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources. See [Cloud Tagging Strategy & Standards](https://experian.atlassian.net/wiki/x/swH3E) for available tags"
}

variable "visibility_timeout_seconds" {
  type        = number
  default     = 30
  description = "The visibility timeout for the queue, in seconds. A number from 0 to 43200 (12 hours)"

  validation {
    condition = (
      var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    )
    error_message = "visibility_timeout_seconds must be between 0 and 43200 seconds, inclusive."
  }
}

variable "disable_default_alarms" {
  type        = bool
  default     = false
  description = "To disable the best practice AWS alarms outlined here in [AWS Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#SQS)"
}

variable "alarm_sns_topics" {
  type        = list(string)
  default     = []
  description = "List of SNS topic ARNs triggered by alarm events. providing a list will automatically enable alarm actions"
}

variable "enable_all_alarm_actions" {
  type        = bool
  description = "Set to `true` to enable alarm actions for `INSUFFICIENT_DATA` and `OK` state for all default alarms. By default, only `ALARM` states will trigger actions"
  default     = false
}

variable "alarm_metric_thresholds" {
  type = object({
    ApproximateAgeOfOldestMessage         = optional(number)
    ApproximateNumberOfMessagesNotVisible = optional(number)
    ApproximateNumberOfMessagesVisible    = optional(number)
    NumberOfMessagesSent                  = optional(number)
  })
  default     = {}
  description = "A map of custom alarm thresholds. See [AWS best practice](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#SQS) for a list of metrics, the name of the metric is the key to use when setting a threshold"
}

variable "cloudwatch_tags" {
  type        = map(string)
  default     = {}
  description = "Cloudwatch Alarm tags. See https://experian.atlassian.net/wiki/x/swH3E for all available tags"
}

variable "prefix" {
  type        = string
  default     = null
  description = "Optional custom prefix to override the eits_ce_common prefix"
}