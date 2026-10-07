# EITS Cloud Enablement AWS SQS Module

EITS Terraform module for AWS Simple Queue Service (SQS). This module will:

- Create an SQS queue
- Configure Server-side encryption (SSE) by default
- Configure SQS queue policy, if required
- Support FIFO (First-In-First-Out) queues, if required
- Support Dead-letter Queues, if required
- Create an "sqs:SendMessage" IAM policy, if required

See CHANGELOG.md for the list of changes for each release.
*We highly recommend that in your code you pin the version to the exact version you are using so that your infrastructure remains stable, and update versions in a systematic way so that they do not catch you by surprise.*

> **IMPORTANT:**
> 
> As of version 1.1.0, default alarms based on [AWS best practice](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#SQS) will be automatically created. This may incur an extra charge of between $0.10 and $0.40 per month for each SQS queue (depending on which thresholds have been set). To disable the creation of these alarms, please set the variable `disable_default_alarms` to true

## EITS Security & Compliance

**Last Module Review**: 2025-01-27

See below for the date and results of our EITS security and compliance scanning.
 
<!-- BEGIN_BENCHMARK_TABLE -->
| Benchmark | Date | Version | Description |
| --------- | ---- | ------- | ----------- |
| ![validate](https://img.shields.io/badge/validate-passed-green) | 2026-02-05 | 1.11.4 | Validates terraform code using example test directories |
| ![tflint](https://img.shields.io/badge/tflint-passed-green) | 2026-02-05 | 0.60.0 | Enforces best practices, syntax, naming conventions |
| ![trivy](https://img.shields.io/badge/trivy-passed-green) | 2026-02-05 | 0.68.2 | Detects misconfiguration in IaC files, such as Docker, Terraform, etc |
| ![wiz](https://img.shields.io/badge/wiz.io_iac-passed-green) | 2026-02-05 | 0.107.0 | Scans tests directory plans for vulnerabilities and risks |
<!-- END_BENCHMARK_TABLE -->

## SQS Topic Resource Naming

This module attempts to adhere to the [EEC Cloud Naming Conventions](https://experian.atlassian.net/wiki/x/XwH3E). Topics will be named as follows:

```
{prefix}-{'name' variable}-sqs-queue
```

Where `prefix` is derived from `eits_ce_common` by default, but can be overridden using the optional module input `prefix`.

## SQS Server-side Encryption (SSE)

- Amazon SQS provides encryption in-transit by default. This module also adds by default a policy to enforce the use of secure transport for sending messages to the SQS queue.
- By default the SQS topic is encrypted with SSE-SQS, see [SQS SSE Docs](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sqs-sse-queue.html), however if you wish to use a KMS Customer Managed Key for queue encryption use the `kms_master_key_id` variable.

## SQS Topic IAM Policy

The module can automatically generate an "sqs:SendMessage" IAM policy for the SQS queue, pass the following variable:

```hcl
policy_allowed_source_arns = ["<arn>"] # list of ARNs to grant access to sqs:SendMessage
```

If you would like to provide a policy json string yourself, use:

```hcl
policy_json = "<fully-formed aws policy as json>"
```

This will override the `policy_allowed_source_arns` variable. Due to the way terraform handles (or doesnt) circular references you will not be able to reference the SQS module when using `policy_json` and must build fully formed ARN values were applicable.

## Usage

### Standard Queue

```hcl
module "sqs_queue" {
	source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-sqs.git"

    # optional: override the default eits_ce_common prefix
    prefix = "<custom prefix>"

    name = "<name of queue>"
    policy_allowed_source_arns = ["<list of arns to grant sqs:SendMessage>"]

    # encyption config - omit if not using own KMS CMK
    kms_master_key_id = "<CMK ID>"

    # optional arguments, omit if using default, see Inputs below for details
    delay_seconds              = <number>
    max_message_size           = <number>
    message_retention_seconds  = <number>
    receive_wait_time_seconds  = <number>
    visibility_timeout_seconds = <number>
    deduplication_scope        = "<scope>"

    tags = {
        Environment = <env>
        CostString  = <CostString>
        AppID       = <AppID>
    }
}
```

### FIFO Queue

```hcl
module "fifo_sqs_queue" {
	source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-sqs.git"

    # optional: override the default eits_ce_common prefix
    prefix = "<custom prefix>"

    name                             = "<name of queue>"
    fifo_queue                       = true
    fifo_content_based_deduplication = <bool>
    fifo_throughput_limit            = "<string>"

    tags = {
        Environment = <env>
        CostString  = <CostString>
        AppID       = <AppID>
    }
}
```

### Dead Letter Queue

When creating dead-letter queues, the existing source queues must be created first.

The dead-letter queue of a FIFO queue must also be a FIFO queue. Similarly, the dead-letter queue of a standard queue must also be a standard queue. For more details see [AWS Docs](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html#sqs-dead-letter-queues-how-they-work)

```hcl
module "dlq_sqs_queue" {
	source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-sqs.git"

    # optional: override the default eits_ce_common prefix
    prefix = "<custom prefix>"

    name              = "<name of queue>"
    dead_letter_queue = true

    dead_letter_queue_source = {
        dlqsource = {
            sourceQueueArn  = "<source queue arn>"
            sourceQueueUrl  = "<source queue url>"
            maxReceiveCount = 10
        }
    }

    tags = {
        Environment = <env>
        CostString  = <CostString>
        AppID       = <AppID>
    }
}
```

The `dead_letter_queue_source` argument takes a map of maps, used to configure the dead letter queue policies, the map key ("dlqsource" in the example above) can be any identifier, it is not used in naming.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.83.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.83.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alarm"></a> [alarm](#module\_alarm) | git::https://code.experian.local/scm/EUCES/eits-tf-aws-cloudwatch-alarm.git | 1.3.0 |
| <a name="module_eits_ce_common"></a> [eits\_ce\_common](#module\_eits\_ce\_common) | git::https://code.experian.local/scm/EUCES/eits-tf-aws-ce-common.git | v1 |

## Resources

| Name | Type |
|------|------|
| [aws_sqs_queue.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_redrive_allow_policy.dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource |
| [aws_sqs_queue_redrive_policy.dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_policy) | resource |
| [aws_default_tags.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_policy_document.enable_secure_transport_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_metric_thresholds"></a> [alarm\_metric\_thresholds](#input\_alarm\_metric\_thresholds) | A map of custom alarm thresholds. See [AWS best practice](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#SQS) for a list of metrics, the name of the metric is the key to use when setting a threshold | <pre>object({<br/>    ApproximateAgeOfOldestMessage         = optional(number)<br/>    ApproximateNumberOfMessagesNotVisible = optional(number)<br/>    ApproximateNumberOfMessagesVisible    = optional(number)<br/>    NumberOfMessagesSent                  = optional(number)<br/>  })</pre> | `{}` | no |
| <a name="input_alarm_sns_topics"></a> [alarm\_sns\_topics](#input\_alarm\_sns\_topics) | List of SNS topic ARNs triggered by alarm events. providing a list will automatically enable alarm actions | `list(string)` | `[]` | no |
| <a name="input_cloudwatch_tags"></a> [cloudwatch\_tags](#input\_cloudwatch\_tags) | Cloudwatch Alarm tags. See https://experian.atlassian.net/wiki/x/swH3E for all available tags | `map(string)` | `{}` | no |
| <a name="input_dead_letter_queue"></a> [dead\_letter\_queue](#input\_dead\_letter\_queue) | Whether or not to create the queue as a dead-letter queue with associated redrive policy. See [AWS Docs](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) for more details | `bool` | `false` | no |
| <a name="input_dead_letter_queue_source"></a> [dead\_letter\_queue\_source](#input\_dead\_letter\_queue\_source) | Configuration for a dead-letter queue. See README.md for more details. Required if `dead_letter_queue` is `true` | <pre>map(object({<br/>    sourceQueueArn  = string<br/>    sourceQueueUrl  = string<br/>    maxReceiveCount = optional(number, 5)<br/>  }))</pre> | `{}` | no |
| <a name="input_deduplication_scope"></a> [deduplication\_scope](#input\_deduplication\_scope) | Specifies whether message deduplication occurs at the message group or queue level. Valid values are `messageGroup` and `queue` (default) | `string` | `null` | no |
| <a name="input_delay_seconds"></a> [delay\_seconds](#input\_delay\_seconds) | The time in seconds that the delivery of messages in the queue will be delayed. A number from 0 seconds to 900 (15 minutes) | `number` | `0` | no |
| <a name="input_disable_default_alarms"></a> [disable\_default\_alarms](#input\_disable\_default\_alarms) | To disable the best practice AWS alarms outlined here in [AWS Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#SQS) | `bool` | `false` | no |
| <a name="input_enable_all_alarm_actions"></a> [enable\_all\_alarm\_actions](#input\_enable\_all\_alarm\_actions) | Set to `true` to enable alarm actions for `INSUFFICIENT_DATA` and `OK` state for all default alarms. By default, only `ALARM` states will trigger actions | `bool` | `false` | no |
| <a name="input_enable_secure_transport_policy"></a> [enable\_secure\_transport\_policy](#input\_enable\_secure\_transport\_policy) | Set to `true` to enforce the use of secure transport for sending messages to the SQS queue. | `bool` | `true` | no |
| <a name="input_fifo_content_based_deduplication"></a> [fifo\_content\_based\_deduplication](#input\_fifo\_content\_based\_deduplication) | Enables content-based deduplication for FIFO queues. Only applicable if `fifo_queue` is `true` | `bool` | `false` | no |
| <a name="input_fifo_queue"></a> [fifo\_queue](#input\_fifo\_queue) | Whether or not to create the queue as FIFO (first-in-first-out), will add .fifo name suffix automatically | `bool` | `false` | no |
| <a name="input_fifo_throughput_limit"></a> [fifo\_throughput\_limit](#input\_fifo\_throughput\_limit) | Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are `perQueue` (default) and `perMessageGroupId`. Only applicable if `fifo_queue` is `true` | `string` | `"perQueue"` | no |
| <a name="input_kms_data_key_reuse_period_seconds"></a> [kms\_data\_key\_reuse\_period\_seconds](#input\_kms\_data\_key\_reuse\_period\_seconds) | The time in seconds for which SQS can reuse a data key to encrypt or decrypt messages before calling KMS again. A number from 60 (1 min) to 86400 (24 hours). Only applicable if `kms_master_key_id` is used | `number` | `300` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK. If supplied, will change encryption from [SSE-SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sqs-sse-queue.html) to [SSE-KMS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sse-existing-queue.html) | `string` | `null` | no |
| <a name="input_max_message_size"></a> [max\_message\_size](#input\_max\_message\_size) | The limit of how many bytes a message can contain before SQS rejects it. A number from 1024 (1 KiB) to 262144 (256 KiB) | `number` | `262144` | no |
| <a name="input_message_retention_seconds"></a> [message\_retention\_seconds](#input\_message\_retention\_seconds) | The time in seconds SQS retains a message. A number from 60 (1 minute) to 1209600 (14 days). | `number` | `345600` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the queue. The actual resource name will be created as `{account_naming_construct}-{name}-sqs-queue` in accordance with the [EEC Cloud Naming Conventions](https://experian.atlassian.net/wiki/x/XwH3E). If `fifo_queue` is set to `true` a .fifo suffix will be automatically added | `string` | n/a | yes |
| <a name="input_policy_allowed_source_arns"></a> [policy\_allowed\_source\_arns](#input\_policy\_allowed\_source\_arns) | Source ARNs that will have permission to send messages from the SQS queue. Used when `policy_json` is not supplied | `list(string)` | `[]` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | The fully-formed AWS policy as JSON, if required. Will override anything specified in `policy_allowed_source_arns` | `string` | `""` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Optional custom prefix to override the eits\_ce\_common prefix | `string` | `null` | no |
| <a name="input_receive_wait_time_seconds"></a> [receive\_wait\_time\_seconds](#input\_receive\_wait\_time\_seconds) | The time in seconds for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. A number from 0 to 20 (seconds). If left at the default `null`, then `0` will be automatically set for resources with an 'Environment' tag of value 'prd', and `20` for other environments. This is a cost-saving measure | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for AWS resources. See [Cloud Tagging Strategy & Standards](https://experian.atlassian.net/wiki/x/swH3E) for available tags | `map(string)` | `{}` | no |
| <a name="input_visibility_timeout_seconds"></a> [visibility\_timeout\_seconds](#input\_visibility\_timeout\_seconds) | The visibility timeout for the queue, in seconds. A number from 0 to 43200 (12 hours) | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_queue_arn"></a> [queue\_arn](#output\_queue\_arn) | SQS queue ARN |
| <a name="output_queue_id"></a> [queue\_id](#output\_queue\_id) | SQS queue ID |
| <a name="output_queue_url"></a> [queue\_url](#output\_queue\_url) | SQS queue URL |
<!-- END_TF_DOCS -->

## Metadata
```discoveryhub
summary: Terraform module for AWS Simple Queue Service (SQS)
region: Global
bu: EITS
contacts:
  technical: EITS UK&I Cloud Enablement Team eitsukicloud@experian.com
  product: 
```
