provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

data "template_file" "user_data" {
  template = file("user-data.sh")
  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }
}



resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [
    aws_security_group.alb.id]
}

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

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  # Разрешаем все входящие HTTP-запросы
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  # Разрешаем все исходящие запросы
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

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

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  condition {
    path_pattern  {
      values = ["*"]
    }
  }
  //    field = "path-pattern" //устарело
  //    values = ["*"]
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}



data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns = [
    aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 1
  max_size = 2
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [
    aws_security_group.instance.id]
  user_data =  data.template_file.user_data.rendered
//  user_data = <<-EOF
//    #!/bin/bash
//    echo "Hello, World" > index.html
//    echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
//    echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
//    echo "Hello, work" > work.html
//    mkdir work
//    echo "work" > work/work.html
//    nohup busybox httpd -f -p ${var.server_port} &
//    EOF
  # Требуется при использовании группы автомасштабирования
  # в конфигурации запуска.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
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
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"
    # Замените это именем своей таблицы DynamoDB!
    dynamodb_table = "terraform-sevod-test-locks"
    encrypt = true
  }
}

#данные с mysql
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "terraform-sevod-test-state"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}
