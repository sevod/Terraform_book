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


###Развертывание кластера веб-серверов (стр. 86)

#####ASG - auto scaling group

#####aws_launch_configuration ресурс описывающий конфигурацию запуска
используется вместо aws_instance и очень похож по настройкам

#####aws_autoscaling_group ресурс описывающий ASG

#####create_before_destroy - параметр жизненного цикла. 
Говорит о том что сначало создаем новое, потом удаляем старое.

C обновлением всех ссылок таким образом, чтобы они указывали на нее, а не
на старый ресурс.

Добавляем его в aws_launch_configuration.

````
lifecycle {
	create_before_destroy = true
}
````


#####subnet_ids - подсети VPS
VPC - виртуальные частные облака (virtual private cloud, или VPC)

Каждая подсеть находится в изолированной зоне доступности AWS (то есть в отдельном
вычислительном центре)

####источник данных (стр. 88)
Источник данных представляет собой фрагмент информации, доступной сугубо для чтения, который извлекается из провайдера (в нашем случае из AWS).

````
data "<PROVIDER>_<TYPE>" "<NAME>" {
 [CONFIG ...]
}
````
NAME — идентификатор, с помощью которого можно ссылаться на этот источник данных в коде Terraform
````
data "aws_vpc" "default" {
 default = true
}
````

#### data.\<PROVIDER>_\<TYPE>.\<NAME>.\<ATTRIBUTE> - получение данных из источника данных
`data.aws_vpc.default.id` - идентификатор VPC из источника данных aws_vpc

####aws_subnet_ids (стр. 89) - источник данных. подсети внутри облака VPC
````
data "aws_subnet_ids" "default" {
	vpc_id = data.aws_vpc.default.id
}
````

####vpc_zone_identifier - аргумент чтобы ваша группа ASG использовала эти подсети
Добавляем в aws_autoscaling_group
````
 launch_configuration = aws_launch_configuration.example.name
 vpc_zone_identifier = data.aws_subnet_ids.default.ids
````

###Балансировщик нагрузки (стр. 90)

####resource "aws_lb"

####Типы балансировщиков
- ALB
- NLB
- CLB
````
resource "aws_lb" "example" {
	name = "terraform-asg-example"
	load_balancer_type = "application"
	subnets = data.aws_subnet_ids.default.ids
	security_groups = [aws_security_group.alb.id]
}
````

####resource "aws_lb_listener" - слушатель

````
resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.example.arn
	port = 80
	protocol = "HTTP"
	# По умолчанию возвращает простую страницу с кодом 404
	default_action {
		type = "fixed-response"
		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = 404
		}
	}
}
````

####Группа безопасности для балансировщика нагрузки

````
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  # Разрешаем все входящие HTTP-запросы
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Разрешаем все исходящие запросы
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
````

и добавляем
####security_groups = [aws_security_group.alb.id]

####ресурс aws_lb_target_group - целевая группа для ASG 
````
resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}
````

Добавляем в aws_autoscaling_group

````
target_group_arns = [aws_lb_target_group.asg.arn]
health_check_type = "ELB"
````

####параметр health_check_type, указывает тип проверки, по умолчанию "EC2"

####ресурс aws_lb_listener_rule
````
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  condition {
    field = "path-pattern"
    values = ["*"]
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
````

####Добавляем вывод dns имени
````
output "alb_dns_name" {
 value = aws_lb.example.dns_name
 description = "The domain name of the load balancer"
}
````

###terraform destroy - удаление

##Гл. 3. Как управлять состоянием Terraform (стр. 100)

####terraform_remote_state - Источник данных

####файл состояния - /foo/bar/terraform.tfstate (не должен быть публичным)

###Настройка S3 
В новой папке aws_s3_bucket создаем новую конфигурацию терраформ

####resource "aws_s3_bucket" это и есть наше хранилище (подробности в файле конфигурации в папке aws_s3_bucket)

####resource "aws_dynamodb_table" таблица DynamoDB, будет использоваться для блокировок
что бы использовать этот код, у вашего пользователя IAM должны быть права на создание бакетов S3 и таблиц DynamoDB (стр. 60)

Делаем `terraform init` и S3 создан.

###переносим локальное состояние в бакет

####backend 
для применения используем `terraform init`
````
terraform {
 backend "s3" {
 # Поменяйте это на имя своего бакета!
 bucket = "terraform-up-and-running-state"
 key = "global/s3/terraform.tfstate"
 region = "us-east-2"
 # Замените это именем своей таблицы DynamoDB!
 dynamodb_table = "terraform-up-and-running-locks"
 encrypt = true
 }
}
````

#####теперь Terraform устанавливает блокировку перед запуском команды apply и снимает ее после!

####Удаление данного бакета
1. Перейти к коду Terraform, удалить конфигурацию backend и снова выполнить
   команду terraform init, чтобы скопировать состояние Terraform обратно на
   локальный диск.
2. Выполнить terraform destroy, чтобы удалить бакет S3 и таблицу DynamoDB

###Переменные в backend (стр. 112)
Мы не можем их там использовать, один из вариантов решения файл backend.hcl:
````
# backend.hcl
bucket = "terraform-up-and-running-state"
region = "us-east-2"
dynamodb_table = "terraform-up-and-running-locks"
encrypt = true
````

В самом терраформ мы оставляем только key
````
# Частичная конфигурация. Другие параметры (такие как bucket, region) будут
# переданы команде 'terraform init' в виде файла с использованием
# аргументов -backend-config
terraform {
   backend "s3" {
      key = "example/terraform.tfstate"
   }
}
````

Для запуска: `$ terraform init -backend-config=backend.hcl`

#####Terragrunt - сторонний инструмент для настройки backend

###Изоляция файлов состояния (стр. 112)
- Изоляция через рабочие области (стр. 113)
- Изоляция с помощью описания структуры файлов (стр. 119)

####Изоляция через рабочие области
`terraform workspace`

- `$ terraform workspace show`
- `$ terraform workspace new example1`
- `$ terraform workspace list` - список workspace
- `$ terraform workspace select example1`

`terraform.workspace` - получить значение workspace
````
resource "aws_instance" "example" {
 ami = "ami-0c55b159cbfafe1f0"
 instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
}
````

####Недостатки изоляции через рабочие области (стр. 119)

###Изоляция с помощью описания структуры файлов(стр. 119)

Создаю новую структуру папок и файлов в 3_stage (стр. 122)

##Источник данных terraform_remote_state (стр. 123)
Источник данных который особенно полезен при работе с состоянием.

####RDS (Relational Database Service)
stage/data-stores/mysql/main.tf:

####aws_secretsmanager_secret_version - Хранение секретных паролей в сервисах AWS Secrets Manager (стр. 125)
````
password = data.aws_secretsmanager_secret_version.db_password.secret_string

data "aws_secretsmanager_secret_version" "db_password" {
 secret_id = "mysql-master-password-stage"
}
````

####второй вариант секретных данных (стр. 126)
создать переменную и брать из энвайремента. В данном случае `TF_VAR_db_password`
````
variable "db_password" {
 description = "The password for the database"
 type = string
}
````
Применяем переменную и запускаем тераформ. 
````
$ export TF_VAR_db_password="(YOUR_DB_PASSWORD)"
$terraform apply
````

####Добавляем выходные переменные sql конфиг, что бы их можно было получать везде
````
output "address" {
 value = aws_db_instance.example.address
 description = "Connect to the database at this endpoint"
}
output "port" {
 value = aws_db_instance.example.port
 description = "The port the database is listening on"
}
````
подключаем бакет так:
````
data "terraform_remote_state" "db" {
 backend = "s3"
 config = {
 bucket = "(YOUR_BUCKET_NAME)"
 key = "stage/data-stores/mysql/terraform.tfstate"
 region = "us-east-2"
 }
}
````
и получаем данные
````
echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
````

###Встроенные функции

####terraform console - для тренировки (только для чтения)

####format("%.3f", 3.14159265359) - одна из функций

####file(<PATH>) - функция читает файл и возращает прочитаное в код терраформ
создадим user-data.sh и будем его читать

`file("user-data.sh")`

####template_file (стр. 132)
на вход принимает template и массив для замены vars
`user_data =  data.template_file.user_data.rendered`
````
data "template_file" "user_data" {
 template = file("user-data.sh")
 vars = {
 server_port = var.server_port
 db_address = data.terraform_remote_state.db.outputs.address
 db_port = data.terraform_remote_state.db.outputs.port
 }
}
````

