data "aws_caller_identity" "current" {}

resource "random_string" "s3_unique_key" {
  length  = 6
  upper   = false
  lower   = true
  number  = true
  special = false
}
