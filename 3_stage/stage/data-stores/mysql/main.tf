provider "aws" {
  region = "us-east-2"
}
resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "example_database"
  username = "admin"
  # Как нам задать пароль?
  password = var.db_password
//  password = data.aws_secretsmanager_secret_version.db_password.secret_string //это вариант для AWS
}

//это вариант для AWS
//data "aws_secretsmanager_secret_version" "db_password" {
//  secret_id = "mysql-master-password-stage"
//}

//с помощью этого когда, мы перенесем данные состояния в S3
//этот код можно применять только после того как создано S3 и dynamodb
//terraform init
terraform {
  backend "s3" {
    # Поменяйте это на имя своего бакета!
    bucket = "terraform-sevod-test-state"
    #место где будет все хранится
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
    # Замените это именем своей таблицы DynamoDB!
    dynamodb_table = "terraform-sevod-test-locks"
    encrypt = true
  }
}
