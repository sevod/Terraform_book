# Terraform_book
Книга. Terraform инфраструктура на уровне кода.

###Первый запуск

#####Добавить ключи в энвайремент линукс
$ export AWS_ACCESS_KEY_ID=(your access key id)
$ export AWS_SECRET_ACCESS_KEY=(your secret access key)

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
соединяется с облаком и проверяет конфигурацию.

#####terraform apply
применяет конфигурацию на облако


#####добавили тег
название сервера
````
tags = {
Name = "terraform-example"
}
````

###Развертывание одного веб-сервера (стр. 72)

#####веб-сервера https://busybox.net/
````
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p 8080 &
````

#####параметр user_data - может исполнить скрипт при старте сервера
````
resource "aws_instance" "example" {
 ami = "ami-0c55b159cbfafe1f0"
 instance_type = "t2.micro"
 user_data = <<-EOF
 #!/bin/bash
 echo "Hello, World" > index.html
 nohup busybox httpd -f -p 8080 &
 EOF
 tags = {
 Name = "terraform-example"
 }
}
````
<<-EOF и EOF начало и конец строки
#####aws_security_group - группа безопасности
создает новый ресурс под названием aws_security_group и делает так, чтобы эта
группа разрешала принимать на порте 8080 TCP-запросы из блока CIDR 0.0.0.0/0.
````
resource "aws_security_group" "instance" {
 name = "terraform-example-instance"
 ingress {
 from_port = 8080
 to_port = 8080
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
}
````

#####что бы применить эту группу в aws_instance добавляем
`vpc_security_group_ids = [aws_security_group.instance.id]`
````
resource "aws_instance" "example" {
ami = "ami-0c55b159cbfafe1f0"
instance_type = "t2.micro"
vpc_security_group_ids = [aws_security_group.instance.id]
user_data = <<-EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p 8080 &
EOF
tags = {
Name = "terraform-example"
}
}
````

#####terraform graph
Посмотреть граф зависимостей

###входные переменные (стр. 80)
Пример:
````
variable "number_example" {
 description = "An example of a number variable in Terraform"
 type = number
 default = 42
}
````

#####type
string, number, bool, list, map, set, object, tuple и any.

Пример:
````
variable "list_numeric_example" {
 description = "An example of a numeric list in Terraform"
 type = list(number)
 default = [1, 2, 3]
}
````
type = map

````
variable "map_example" {
 description = "An example of a map in Terraform"
 type = map(string)
 default = {
 key1 = "value1"
 key2 = "value2"
 key3 = "value3"
 }
}
````
type = object
````
variable "object_example" {
 description = "An example of a structural type in Terraform"
 type = object({
 name = string
 age = number
 tags = list(string)
 enabled = bool
 })
 default = {
 name = "value1"
 age = 42
 tags = ["a", "b", "c"]
 enabled = true
 }
}
````
#####default -если отсутствует то при apply попросит ввести или 
`terraform plan -var "server_port=8080"`
````
variable "server_port" {
description = "The port the server will use for HTTP requests"
type = number
}
````

#####можно использовать env (TF_VAR_ будет откинуто)
export TF_VAR_server_port=8080

#####что бы воспользоваться переменной
`from_port = var.server_port`

или внутри строки

`"${var.server_port}"`

###выходные переменные (стр. 84)

````
output "<NAME>" {
 value = <VALUE>
 [CONFIG ...]
}
````

#####Пример выведет IP
````
output "public_ip" {
 value = aws_instance.example.public_ip
 description = "The public IP address of the web server"
}
````

#####terraform output public_ip
Можно ввести в консоли и мы получим значение переменной public_ip