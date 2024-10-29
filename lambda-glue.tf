data "archive_file" "lambda_function_file2" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda-glue.py"
  output_path = "${path.module}/lambda-glue.zip"
}


resource "aws_iam_policy" "lambda_glue_policy" {
  name = "${var.app_env}-lambda-glue-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "glue:StartJobRun"
        ]
        Effect   = "Allow"
        Resource = aws_glue_job.json_to_parquet.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_glue_policy_attachment" {
  role       = aws_iam_role.iam_role_for_simple_pipeline.name
  policy_arn = aws_iam_policy.lambda_glue_policy.arn
}


resource "aws_lambda_function" "invoke_lambda_job" {
  filename         = data.archive_file.lambda_function_file2.output_path
  function_name    = "${var.app_env}-lambda-glue"
  role             = aws_iam_role.iam_role_for_simple_pipeline.arn
  handler          = "lambda-glue.handler" # Ensure this matches your Python file
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_function_file2.output_base64sha256

  environment {
    variables = {
      GLUE_JOB_NAME = aws_glue_job.json_to_parquet.name
      TARGET_BUCKET = aws_s3_bucket.target_bucket.id
      INPUT_PREFIX  = "cleaned/"
      OUTPUT_PREFIX = "parquet/"
    }
  }
}