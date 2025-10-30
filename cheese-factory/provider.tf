# Archivo: cheese-factory/provider.tf

terraform {
  # --- CONFIGURACIÓN DEL BACKEND REMOTO (REQUISITO ESTADO REMOTO) ---
  backend "s3" {
    # Reemplaza 'tf-cheese-factory-estado-remoto-tu-nombre-12345'
    # con el nombre EXACTO que se generó y desplegó en s3-backend-bootstrap/main.tf
    bucket         = "tf-cheese-factory-estado-remoto-edoturbina-12345" 
    
    # Nombre del archivo de estado dentro del bucket (sin variables)
    key            = "cheese-factory/terraform.tfstate" 
    
    region         = "us-east-1"
    encrypt        = true
    
    # Nombre de la tabla DynamoDB para bloqueo de estado
    dynamodb_table = "tf-cheese-factory-state-lock" 
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuración del proveedor AWS
provider "aws" {
  region = var.region
}