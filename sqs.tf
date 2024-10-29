resource "aws_sqs_queue" "sqs_queue" {
  name = "${var.app_env}-simple-pipeline"

  policy = <<POLICY
  {
   "Version": "2012-10-17",
   "Id": "SIMPLE-QUEUE",
   "Statement": [{
      "Sid":"Queue1_SendMessage",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:${var.app_env}-simple-pipeline",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.source_bucket.arn}"}
      }
   }]  
}
  POLICY
}