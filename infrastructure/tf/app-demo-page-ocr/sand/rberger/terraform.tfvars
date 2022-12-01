bucket_prefix = "informed"
environment   = "rberger"
project_name  = "techno-core"
profile       = "rberger"
region        = "us-west-2"
runtime       = "python3.7"
architectures = ["x86_64"]
memory_size   = "1024"
layer_arns = [
  "arn:aws:lambda:us-west-2:230151955380:layer:open-cv-python-3-7:1"
]

lambda_handler_name = "app_demo_page_ocr.handler"
