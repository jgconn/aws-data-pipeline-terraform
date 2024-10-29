resource "aws_cloudwatch_event_rule" "eventbridge_s3_trigger" {
  name        = "s3_event_rule"
  description = "Capture S3 upload test"

  event_pattern = <<EOF
{
  "detail": {
    "bucket": {
      "name": ["${aws_s3_bucket.target_bucket.id}"]
    },
    "object": {
      "key": [{
        "prefix": "cleaned/"
      }]
    }
  },
  "detail-type": ["Object Created"],
  "source": ["aws.s3"]
}
EOF
}

resource "aws_cloudwatch_event_target" "glue_event_target" {
  rule      = aws_cloudwatch_event_rule.eventbridge_s3_trigger.name
  target_id = "triggerGlueJob"
  arn       = aws_lambda_function.invoke_lambda_job.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.invoke_lambda_job.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eventbridge_s3_trigger.arn
}

resource "aws_cloudwatch_event_rule" "glue_job_status_trigger" {
  name        = "glue-job-status"
  description = "Rule to monitor Glue job status changes"
  event_pattern = jsonencode({
    "source" : ["aws.glue"],
    "detail-type" : ["Glue Job State Change"],
    "detail" : {
      "jobName" : ["${aws_glue_job.json_to_parquet.name}"],
      "state" : ["SUCCEEDED", "FAILED", "STARTING"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule = aws_cloudwatch_event_rule.glue_job_status_trigger.name
  arn  = aws_sns_topic.notifications.arn
}