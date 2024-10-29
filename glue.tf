resource "aws_s3_object" "deploy_script_s3" {
  bucket = aws_s3_bucket.target_bucket.id
  key    = "script/testGlueJob.py"
  source = "${path.module}/glue/testGlueJob.py"
  etag   = filemd5("${path.module}/glue/testGlueJob.py")
}

resource "aws_glue_job" "json_to_parquet" {
  name              = "${var.app_env}-test-deploy"
  description       = "test glue job and convert json to parquet"
  role_arn          = aws_iam_role.glue_service_role.arn
  max_retries       = 0
  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = "60"
  command {
    script_location = "s3://${aws_s3_bucket.target_bucket.id}/script/testGlueJob.py"
    python_version  = "3"
  }
  default_arguments = {
    "--class"                   = "GlueApp"
    "--enable-job-insights"     = "true"
    "--enable-auto-scaling"     = "false"
    "--enable-glue-datacatalog" = "true"
    "--job-language"            = "python"
    "--job-bookmark-option"     = "job-bookmark-disable"
    "--datalake-formats"        = "iceberg"
    "--conf"                    = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions  --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog  --conf spark.sql.catalog.glue_catalog.warehouse=s3://tnt-erp-sql/ --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog  --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO"

  }
}

resource "aws_glue_catalog_database" "glue_catalog_db" {
  name = "justincatalogdb"
}

resource "aws_iam_role" "glue_crawler_role" {
  name = "${var.app_env}-glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "glue_crawler_policy" {
  name = "${var.app_env}-glue-crawler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.target_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.target_bucket.id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable",
          "glue:GetTable",
          "glue:GetDatabase"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_crawler_policy" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_crawler_policy.arn
}

resource "aws_glue_crawler" "parquet_crawler" {
  name          = "${var.app_env}-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.glue_catalog_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.target_bucket.id}/parquet/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
  }

  configuration = <<EOF
{
  "Version": 1.0,
  "Grouping": {
    "TableGroupingPolicy": "CombineCompatibleSchemas"
  }
}
EOF
}