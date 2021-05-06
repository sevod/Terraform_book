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

