bucket_prefix = "informed"
environment   = "dev-api"
project_name  = "techno-core"
profile       = "dev-api"
region        = "us-west-2"
runtime       = "python3.7"
architectures = ["x86_64"]
memory_size   = "4096"
layer_arns = [
  "arn:aws:lambda:us-west-2:473038670073:layer:open-cv-python-3-7:1"
]

lambda_handler_name = "app_demo_page_ocr.handler.handler"
