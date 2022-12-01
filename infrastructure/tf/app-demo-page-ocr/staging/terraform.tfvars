bucket_prefix = "informed"
environment   = "staging"
project_name  = "techno-core"
profile       = "staging"
region        = "us-west-2"
runtime       = "python3.7"
architectures = ["x86_64"]
memory_size   = "4096"
layer_arns = [
  "arn:aws:lambda:us-west-2:120244891341:layer:open-cv-python-3-7:1"
]

lambda_handler_name = "app_demo_page_ocr.handler.handler"
