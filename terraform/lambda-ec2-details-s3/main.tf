locals {
  unique_no = formatdate("YYYYMMDDhhmmss", timestamp())
  file_name = "ec2-instance-details-${local.unique_no}.zip"
  schedule_expression = "cron(0 */12 * * ? *)"
}

# Source and destination s3 bucket
resource "aws_s3_bucket" "ec2_instance_details_source" {
  bucket_prefix = "ec2-instance-details-source"
  force_destroy = true
}

resource "aws_s3_bucket" "ec2_instance_details_destination" {
  bucket_prefix = "ec2-instance-details-destination"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket_acl_source" {
  bucket = aws_s3_bucket.ec2_instance_details_source.id
  acl    = "private"
}

resource "aws_s3_bucket_acl" "bucket_acl_destination" {
  bucket = aws_s3_bucket.ec2_instance_details_destination.id
  acl    = "private"
}

# Creating zip package of python code
data "archive_file" "ec2_instance_details" {
  type = "zip"

  source_dir  = "${path.module}/ec2-instance-details"
  output_path = "${path.module}/${local.file_name}"
}

# Uploading zip package to source s3 bucket
resource "aws_s3_object" "ec2_instance_details" {
  bucket = aws_s3_bucket.ec2_instance_details_source.id

  key    = local.file_name
  source = data.archive_file.ec2_instance_details.output_path

  etag = filemd5(data.archive_file.ec2_instance_details.output_path)
}

# Lambda function
resource "aws_lambda_function" "ec2_instance_details" {
  function_name = "Ec2InstanceDetails"

  s3_bucket = aws_s3_bucket.ec2_instance_details_source.id
  s3_key    = aws_s3_object.ec2_instance_details.key

  runtime = "python3.9"
  handler = "ec2-instance-details.ec2_instance_details"

  source_code_hash = data.archive_file.ec2_instance_details.output_base64sha256

  role = aws_iam_role.ec2_instance_details.arn
  
  timeout = 15

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.ec2_instance_details_destination.bucket
    }
  }
}

resource "aws_cloudwatch_log_group" "ec2_instance_details" {
  name = "/aws/lambda/${aws_lambda_function.ec2_instance_details.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "ec2_instance_details" {
  name = "Ec2InstanceDetails"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_instance_details_source" {
  role       = aws_iam_role.ec2_instance_details.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for pushing csv files to destination s3 bucket
data "aws_iam_policy_document" "ec2_instance_details" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.ec2_instance_details_destination.bucket}/*",
    ]
  }
}

resource "aws_iam_policy" "ec2_instance_details" {
  name   = "Ec2InstanceDetails"
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_instance_details.json
}

resource "aws_iam_role_policy_attachment" "ec2_instance_details_custom" {
  role       = aws_iam_role.ec2_instance_details.name
  policy_arn = aws_iam_policy.ec2_instance_details.arn
}

# Triggering Lambda twice a day
resource "aws_cloudwatch_event_rule" "ec2_instance_details" {
  name                = "trigger-ec2-details-lambda-twice-a-day"
  description         = "Fires twice a day"
  schedule_expression = local.schedule_expression
}

resource "aws_cloudwatch_event_target" "ec2_instance_details" {
  rule      = "${aws_cloudwatch_event_rule.ec2_instance_details.name}"
  target_id = "lambda"
  arn       = "${aws_lambda_function.ec2_instance_details.arn}"
}

resource "aws_lambda_permission" "ec2_instance_details" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ec2_instance_details.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.ec2_instance_details.arn}"
}