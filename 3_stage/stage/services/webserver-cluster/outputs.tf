output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

//для теста
output "aws_vpc" {
  value = data.aws_vpc.default.id
  description = "output aws_vpc"
}

//для теста
output "aws_subnet_ids" {
  value = data.aws_vpc.default.id
  description = "output aws_subnet_ids"
}