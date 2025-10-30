variable "region" {
  description = "Región de AWS donde se desplegará la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno de despliegue: 'dev' (t2.micro) o 'prod' (t3.small)."
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "El valor de 'environment' debe ser 'dev' o 'prod'."
  }
}

variable "my_public_ip" {
  description = "Tu dirección IP pública con máscara /32 para el acceso SSH seguro al EC2."
  type        = string
  default     = "203.0.113.45/32" 
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC."
  type        = string
  default     = "10.0.0.0/16"
}