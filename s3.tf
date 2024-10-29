resource "aws_s3_bucket" "source_bucket" {
  bucket        = "${var.app_env}-source-bucket"
  force_destroy = true
}

resource "aws_s3_bucket" "target_bucket" {
  bucket        = "${var.app_env}-target-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.source_bucket.id

  queue {
    queue_arn = aws_sqs_queue.sqs_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "target_bucket_notification" {
  bucket      = aws_s3_bucket.target_bucket.id
  eventbridge = true
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.sqs_queue.arn
  enabled          = true
  function_name    = aws_lambda_function.process_s3_upload.arn
  batch_size       = 1
}