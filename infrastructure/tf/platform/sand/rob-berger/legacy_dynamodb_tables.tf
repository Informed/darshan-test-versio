module "legacy_dynamodb_tables" {
  for_each = toset([
    "${var.environment}_document_data",
    "${var.environment}_image_vision_data",
    "${var.environment}_stipulation_document_data"
  ])

  source = "../../../modules/dynamodb"

  dynamodb_name = each.key
}
