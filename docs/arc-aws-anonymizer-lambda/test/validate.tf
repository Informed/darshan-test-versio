module "lambda_function" {
  source = "../"

  app_name            = "data-analysis"
  src_bucket          = "techno-core-bucket-excchange"
  dest_bucket         = "data-shift-bucket"
  environment         = "dev"

  providers = {
    aws.source = aws.source
    aws.dest   = aws.dest
  }
}
