# Este archivo DEBE estar en la carpeta s3-backend-bootstrap/

# Define las variables de este pequeño módulo de bootstrapping
variable "bucket_name_prefix" {
  description = "Prefijo para el nombre del bucket de estado. Debe ser único globalmente."
  default     = "tf-cheese-factory-estado-remoto-edoturbina-12345" 
}

# --- Recursos de Soporte ---

# 1. Bucket S3 para el Estado de Terraform (Módulo Público)
module "s3_state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  # Creamos un nombre único. ¡Cambia 12345 a algo aleatorio!
  bucket = var.bucket_name_prefix

  # Requisitos de Seguridad
  versioning = {
    enabled = true
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true 
}

# 2. Tabla DynamoDB para Bloqueo de Estado (State Locking)
resource "aws_dynamodb_table" "dynamodb_state_lock" {
  # Este nombre será referenciado en el módulo cheese-factory/provider.tf
  name           = "tf-cheese-factory-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_id" {
  value = module.s3_state_bucket.s3_bucket_id
}