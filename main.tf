provider "aws" {
  region = var.region
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "lambda" {
  source = "./modules/lambda"
  tables = [module.dynamodb.tables]
}


output "doi_url" {
  value = module.lambda.doi_put-url
}
