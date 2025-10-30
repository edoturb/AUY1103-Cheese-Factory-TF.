# 🧀 Cheese Factory - Infraestructura AWS con Terraform

## 📋 Descripción del Proyecto

Este proyecto implementa una infraestructura completa en AWS para una aplicación web llamada "Cheese Factory" utilizando Terraform. La infraestructura incluye VPC multi-zona, instancias EC2, security groups, y manejo de estado remoto.

## 🏗️ Arquitectura Desplegada

### Recursos Creados (28 total):
- **1 VPC** con CIDR 10.0.0.0/16
- **6 Subredes** (3 públicas + 3 privadas) distribuidas en 3 AZs
- **3 Instancias EC2** (t3.small) con servidores web Nginx
- **2 Security Groups** (ALB y EC2) con principio de mínimo privilegio
- **1 NAT Gateway** para conectividad de instancias privadas
- **1 Internet Gateway** para acceso público
- **Tablas de rutas** y asociaciones completas
- **Backend S3** con bloqueo DynamoDB

## 🚀 Características Implementadas

### ✅ Requisitos Técnicos:
1. **Lógica Condicional**: Tipo de instancia basado en environment (dev: t2.micro, prod: t3.small)
2. **Módulo Público**: VPC usando `terraform-aws-modules/vpc/aws`
3. **Seguridad**: SSH restringido a IP específica, HTTP solo desde ALB
4. **Estado Remoto**: S3 + DynamoDB con cifrado y versionado
5. **Funciones Nativas**: `format()`, `upper()`, `contains()` para recursos

## 📁 Estructura del Proyecto

```
AUY1103-Cheese-Factory-TF/
├── README.md
├── .gitignore
├── cheese-factory/
│   ├── main.tf                 # Recursos principales
│   ├── variables.tf            # Variables de configuración
│   ├── provider.tf             # Configuración de proveedores
│   └── terraform.tfvars.example # Ejemplo de variables
└── s3-backend-bootstrap/
    ├── main.tf                 # Recursos del backend S3
    └── provider.tf             # Configuración del backend
```

## 🔧 Instrucciones de Despliegue

### 1. Prerequisitos
- AWS CLI configurado
- Terraform >= 1.0
- Permisos de AWS para crear recursos EC2, VPC, S3, DynamoDB

### 2. Configuración Inicial

#### a) Desplegar Backend S3:
```bash
cd s3-backend-bootstrap
terraform init
terraform apply
```

#### b) Configurar variables:
```bash
cd ../cheese-factory
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores
```

#### c) Desplegar infraestructura principal:
```bash
terraform init
terraform plan
terraform apply
```

### 3. Variables Requeridas

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `environment` | Entorno de despliegue | `"prod"` o `"dev"` |
| `region` | Región de AWS | `"us-east-1"` |
| `my_public_ip` | Tu IP pública para SSH | `"203.0.113.45/32"` |
| `vpc_cidr` | CIDR de la VPC | `"10.0.0.0/16"` |

## 🔐 Configuración de Seguridad

### Security Groups:
- **ALB-SG**: HTTP (80) desde 0.0.0.0/0
- **EC2-SG**: 
  - SSH (22) solo desde IP específica
  - HTTP (80) solo desde ALB-SG

### Instancias EC2:
- Ubicadas en subredes privadas
- Sin IPs públicas
- Acceso a internet via NAT Gateway
- Nginx preinstalado via user-data

## 📊 Estado de la Infraestructura

### Instancias Desplegadas:
- **CheeseServer-prod-1**: `i-0bbab12a5f5571683` (10.0.101.224)
- **CheeseServer-prod-2**: `i-0229584f3f052d2c0` (10.0.102.152)
- **CheeseServer-prod-3**: `i-0d075a03f891bb019` (10.0.103.243)

### Backend Remoto:
- **Bucket S3**: `tf-cheese-factory-estado-remoto-edoturbina-12345`
- **Tabla DynamoDB**: `tf-cheese-factory-state-lock`

## 🧹 Limpieza de Recursos

Para destruir toda la infraestructura:

```bash
# Destruir infraestructura principal
cd cheese-factory
terraform destroy

# Destruir backend (opcional)
cd ../s3-backend-bootstrap
terraform destroy
```

## 👨‍💻 Autor

**Eduardo Urbina**
- GitHub: [@edoturb](https://github.com/edoturb)
- Proyecto: AUY1103 - Automatización y Herramientas DevOps

---

⚡ **Estado**: ✅ Desplegado y Funcionando
🏗️ **Recursos**: 28 recursos AWS activos
🔒 **Seguridad**: Implementada con principio de mínimo privilegio
Despliegue Profesional de "The Cheese Factory" con Módulos Públicos y Estado Remoto
