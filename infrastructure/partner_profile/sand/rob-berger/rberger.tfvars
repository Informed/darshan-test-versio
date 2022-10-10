bucket_prefix = "informed"
environment   = "rberger"
project_name  = "techno-core"
profile       = "rberger"
runtime       = "python3.8"
architectures = ["x86_64"]
memory_size   = "1024"
layer_arns = [
  "arn:aws:lambda:us-west-2:901920570463:layer:aws-otel-python-amd64-ver-1-11-1:2",
  # "arn:aws:lambda:us-west-2:545538059309:layer:slsdebugger-python:2",
]

lambda_handler_name = "partner_profile.handler"
# lambda_handler_name = "slsdebugger.handler.wrapper"
# extra_environment_variables = {
#   "SLSDEBUGGER_AUTH_TOKEN"     = "YoPj5Ha1GB3s5jrAyqFqnUjk1WO2OlVCDsUCdrDhxKY="
#   "SLSDEBUGGER_LAMBDA_HANDLER" = "partner_profile.handler"
# }
