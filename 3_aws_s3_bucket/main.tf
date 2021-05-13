provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
  #Это имя бакета S3.
  bucket = "terraform-sevod-test-state"
  # Предотвращаем случайное удаление этого бакета S3
  lifecycle {
    prevent_destroy = true
  }
  # Включаем управление версиями, чтобы вы могли просматривать
  # всю историю ваших файлов состояния
  versioning {
    enabled = true
  }
  # Включаем шифрование по умолчанию на стороне сервера
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


resource "aws_dynamodb_table" "terraform_locks" {
  //имя бакета
  name = "terraform-sevod-test-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

//с помощью этого когда, мы перенесем данные состояния в S3
//этот код можно применять только после того как создано S3 и dynamodb
//terraform init
terraform {
  backend "s3" {
    # Поменяйте это на имя своего бакета!
    bucket = "terraform-sevod-test-state"
    #место где будет все хранится
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"
    # Замените это именем своей таблицы DynamoDB!
    dynamodb_table = "terraform-sevod-test-locks"
    encrypt = true
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
value = aws_dynamodb_table.terraform_locks.name
description = "The name of the DynamoDB table"
}