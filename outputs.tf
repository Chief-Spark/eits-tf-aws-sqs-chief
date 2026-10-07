output "queue_id" {
  value       = aws_sqs_queue.this.id
  description = "SQS queue ID"
}

output "queue_arn" {
  value       = aws_sqs_queue.this.arn
  description = "SQS queue ARN"
}

output "queue_url" {
  value       = aws_sqs_queue.this.url
  description = "SQS queue URL"
}
