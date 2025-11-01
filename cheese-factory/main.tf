# Archivo: cheese-factory/main.tf

# Requisito 5: Expresión Condicional (Tipo de Instancia)
locals {
  # Si var.environment es "prod", usa "t3.small", si no ("dev"), usa "t2.micro".
  instance_type = var.environment == "prod" ? "t3.small" : "t2.micro"
  
  # Usamos una función nativa (format) para nombrar recursos, cumpliendo el Requisito 5
  project_tags = {
    Name        = format("CheeseFactory-%s", upper(var.environment))
    Environment = var.environment
  }
}

# Requisito 2: Uso del Módulo Público para la Red
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name    = format("%s-VPC", local.project_tags.Name)
  cidr    = var.vpc_cidr
  azs     = ["${var.region}a", "${var.region}b", "${var.region}c"] # Tres AZs

  # Subredes públicas para el ALB
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  # Subredes privadas para las instancias EC2
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  
  tags = local.project_tags
}

# Requisito 4: Security Group del ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = module.vpc.vpc_id
  name   = format("%s-ALB-SG", local.project_tags.Name)

  # Tráfico HTTP (80) desde CUALQUIER LUGAR (0.0.0.0/0)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Requisito 4: Security Group de las EC2 (Mínimo Privilegio)
resource "aws_security_group" "ec2_sg" {
  vpc_id = module.vpc.vpc_id
  name   = format("%s-EC2-SG", local.project_tags.Name)

  # 1. Tráfico HTTP (80) permitido SOLO desde el SG del ALB
  ingress {
    description     = "Acceso web solo desde ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Referencia al SG del ALB
  }

  # 2. Tráfico SSH (22) permitido SOLO desde tu IP pública (variable)
  ingress {
    description = "Acceso SSH para administracion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_public_ip] # Restringido a tu /32
  }
}

# Buscamos una AMI para los servidores web (Amazon Linux 2)
data "aws_ami" "web_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Despliegue de las 3 instancias EC2
resource "aws_instance" "web_servers" {
  count         = 3 
  ami           = data.aws_ami.web_ami.id
  instance_type = local.instance_type # Tipo de instancia condicional (t2.micro o t3.small)
  
  # Se despliegan en las subredes privadas
  subnet_id     = module.vpc.private_subnets[count.index] 
  
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name        = format("CheeseServer-%s-%d", var.environment, count.index + 1)
    Environment = var.environment
  }
  
  # Ejemplo simple de userdata para simular un servidor web (Instala Nginx)
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "<h1>Hello from The Cheese Factory Server ${count.index + 1} (${var.environment})</h1>" | sudo tee /usr/share/nginx/html/index.html
              EOF
}

# Application Load Balancer para acceso web público
resource "aws_lb" "cheese_factory_alb" {
  name               = "cheese-factory-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = merge(local.project_tags, {
    Name = "CheeseFactory-${upper(var.environment)}-ALB"
  })
}

# Target Group para las instancias EC2
resource "aws_lb_target_group" "web_servers" {
  name     = "cheese-factory-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.project_tags, {
    Name = "CheeseFactory-${upper(var.environment)}-TG"
  })
}

# Asociar las instancias EC2 al Target Group
resource "aws_lb_target_group_attachment" "web_servers" {
  count            = 3
  target_group_arn = aws_lb_target_group.web_servers.arn
  target_id        = aws_instance.web_servers[count.index].id
  port             = 80
}

# Listener del ALB para HTTP
resource "aws_lb_listener" "web_servers" {
  load_balancer_arn = aws_lb.cheese_factory_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }
}

# Output para mostrar la URL del ALB
output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.cheese_factory_alb.dns_name
}

output "alb_url" {
  description = "URL completa para acceder a la aplicación web"
  value       = "http://${aws_lb.cheese_factory_alb.dns_name}"
}