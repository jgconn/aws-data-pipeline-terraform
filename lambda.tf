data "archive_file" "lambda_function_file" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.app_env}-lambda-policy"
  description = "IAM policy for simple pipeline"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          "${aws_s3_bucket.source_bucket.arn}/*",
          aws_s3_bucket.target_bucket.arn,
          "${aws_s3_bucket.target_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.sqs_queue.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "iam_role_for_simple_pipeline" {
  name = "${var.app_env}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "simple-pipeline_policy_exec" {
  role       = aws_iam_role.iam_role_for_simple_pipeline.id
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "process_s3_upload" {
  filename         = data.archive_file.lambda_function_file.output_path
  function_name    = "${var.app_env}-lambda"
  role             = aws_iam_role.iam_role_for_simple_pipeline.arn
  handler          = "lambda.handler" # Ensure this matches your Python file
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_function_file.output_base64sha256

  environment {
    variables = {
      TARGET_BUCKET = aws_s3_bucket.target_bucket.id
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.process_s3_upload.function_name}"
  retention_in_days = 1
}
