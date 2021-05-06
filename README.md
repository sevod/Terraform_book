# Terraform_book
Книга. Terraform инфраструктура на уровне кода.

###Первый запуск

````
provider "aws" {
region = "eu-west-3"
}

resource "aws_instance" "example" {
ami = "ami-0c55b159cbfafe1f0"
instance_type = "t2.micro"
}
````
#####AMI-Amazon Machine Image
https://aws.amazon.com/marketplace/

#####instance_type
https://aws.amazon.com/ru/ec2/instance-types/

#####terraform init
Первичная иницилизация проекта терраформ.

#####terraform plan
