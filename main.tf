provider "aws" {
  region     = "var.region"
  access_key = "PROVIDE_YOUR_KEY"
  secret_key = "PROVIDE_YOUR_KEY"
}

resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "demo-${random_string.random.result}"
  force_destroy = true

}

resource "aws_s3_bucket_website_configuration" "blog" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }

}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_s3_object" "uploadobject" {
  for_each     = fileset("html/", "*")
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "html/${each.value}"
  etag         = filemd5("html/${each.value}")
  content_type = "text/html"

}

resource "aws_s3_bucket_policy" "read_access_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

output "endpoint" {
  value = aws_s3_bucket_website_configuration.blog.website_endpoint

}

