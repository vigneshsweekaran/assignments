# Source and destination s3 bucket
resource "aws_s3_bucket" "ec2_instance_details_source" {
  bucket_prefix = "ec2_instance_details_source"
}

resource "aws_s3_bucket" "ec2_instance_details_destination" {
  bucket_prefix = "ec2_instance_details_destination"
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
  output_path = "${path.module}/ec2-instance-details.zip"
}

# Uploading zip package to source s3 bucket
resource "aws_s3_object" "ec2_instance_details" {
  bucket = aws_s3_bucket.ec2_instance_details_source.id

  key    = "ec2-instance-details.zip"
  source = data.archive_file.ec2_instance_details.output_path

  etag = filemd5(data.archive_file.ec2_instance_details.output_path)
}

# Lambda function
resource "aws_lambda_function" "ec2_instance_details" {
  function_name = "Ec2InstanceDetails"

  s3_bucket = aws_s3_bucket.ec2_instance_details_source.id
  s3_key    = aws_s3_object.ec2_instance_details.key

  runtime = "python3.9"
  handler = "ec2-instance-details.handler"

  source_code_hash = data.archive_file.ec2_instance_details.output_base64sha256

  role = aws_iam_role.ec2_instance_details.arn
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
data "aws_iam_policy_document" "ec2_instance_details_s3_write_access" {
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

resource "aws_iam_policy" "ec2_instance_details_s3_write_access" {
  name   = "Ec2InstanceDetailsS3WriteAccess"
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_instance_details_s3_write_access.json
}

resource "aws_iam_role_policy_attachment" "ec2_instance_details_destination" {
  role       = aws_iam_role.ec2_instance_details.name
  policy_arn = aws_iam_policy.ec2_instance_details_s3_write_access.arn
}