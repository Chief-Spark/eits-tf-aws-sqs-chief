locals {
  actions_enabled = length(var.alarm_sns_topics) > 0 ? true : false
  alarm_data = {
    ApproximateAgeOfOldestMessage = {
      alarm_description   = "This alarm is used to detect whether the age of the oldest message in the QueueName queue is too high."
      metric_name         = "ApproximateAgeOfOldestMessage"
      statistic           = "Maximum"
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      threshold           = lookup(var.alarm_metric_thresholds, "ApproximateAgeOfOldestMessage", null)
      comparison_operator = "GreaterThanOrEqualToThreshold"
      alarm_enabled       = lookup(var.alarm_metric_thresholds, "ApproximateAgeOfOldestMessage", null) != null
    },
    ApproximateNumberOfMessagesNotVisible = {
      alarm_description   = "This alarm helps to detect a high number of in-flight messages with respect to QueueName."
      metric_name         = "ApproximateNumberOfMessagesNotVisible"
      statistic           = "Average"
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      threshold           = lookup(var.alarm_metric_thresholds, "ApproximateNumberOfMessagesNotVisible", null)
      comparison_operator = "GreaterThanOrEqualToThreshold"
      alarm_enabled       = lookup(var.alarm_metric_thresholds, "ApproximateNumberOfMessagesNotVisible", null) != null
    },
    ApproximateNumberOfMessagesVisible = {
      alarm_description   = "This alarm is used to detect whether the message count of the active queue is too high and consumers are slow to process the messages or there are not enough consumers to process them."
      metric_name         = "ApproximateNumberOfMessagesVisible"
      statistic           = "Average"
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      threshold           = lookup(var.alarm_metric_thresholds, "ApproximateNumberOfMessagesVisible", null)
      comparison_operator = "GreaterThanOrEqualToThreshold"
      alarm_enabled       = lookup(var.alarm_metric_thresholds, "ApproximateNumberOfMessagesVisible", null) != null
    },
    NumberOfMessagesSent = {
      alarm_description   = "This alarm is used to detect when a producer stops sending messages."
      metric_name         = "NumberOfMessagesSent"
      statistic           = "Sum"
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      threshold           = lookup(var.alarm_metric_thresholds, "NumberOfMessagesSent", 0)
      comparison_operator = "LessThanOrEqualToThreshold"
      alarm_enabled       = true
    }
  }
  cloudwatch_tags = merge(var.tags, var.cloudwatch_tags)
}

module "alarm" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-cloudwatch-alarm.git?ref=1.3.0"

  for_each = var.disable_default_alarms ? {} : { for k, v in local.alarm_data : k => v if v.alarm_enabled }

  alarm_name        = format("AWS/SQS %s QueueName=%s", each.value.metric_name, reverse(split(":", aws_sqs_queue.this.arn))[0])
  alarm_description = each.value.alarm_description
  metric_name       = each.value.metric_name
  namespace         = "AWS/SQS"
  statistic         = each.value.statistic
  period            = each.value.period
  dimensions = {
    QueueName = reverse(split(":", aws_sqs_queue.this.arn))[0]
  }
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  threshold           = each.value.threshold
  comparison_operator = each.value.comparison_operator
  treat_missing_data  = "missing"

  actions_enabled           = local.actions_enabled
  alarm_actions             = var.alarm_sns_topics
  insufficient_data_actions = var.enable_all_alarm_actions ? var.alarm_sns_topics : []
  ok_actions                = var.enable_all_alarm_actions ? var.alarm_sns_topics : []

  tags = merge(local.cloudwatch_tags, { "eitsce:parentmodule" = "eits-tf-aws-sqs" })
}