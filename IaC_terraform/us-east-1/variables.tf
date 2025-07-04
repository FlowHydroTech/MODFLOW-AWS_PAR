variable "aws_region" {
  default = "us-east-1"
}

variable "ID_PARAMETRO" {
  description = "ID de parámetro para el modelo"
  type        = string
  default     = "0"
}

variable "ecr_image_mpupio" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-mpupio:latest"
}

variable "ecr_image_mpupio_cb" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-mpupio-cb:latest"
}

variable "ecr_image_mpupio_evu" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-mpupio-evu:latest"
}

variable "ecr_image_pelambres_cb_op" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-pelambres-cb-op:latest"
}

variable "ecr_image_pelambres_evu_op" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-pelambres-evu-op:latest"
}

variable "ecr_image_pelambres_cb_cierre" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-pelambres-cb-cierre:latest"
}

variable "ecr_image_pelambres_evu_cierre" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-pelambres-evu-cierre:latest"
}

variable "ecr_image_choapa" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-choapa:latest"
}

variable "ecr_image_choapa_cb" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-choapa-cb:latest"
}

variable "ecr_image_choapa_evu" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-choapa-evu:latest"
}

variable "common_tags_icsara" {
  type = map(string)
  default = {
    Region  = "us-east-1"
    Service = "FARGATE"
    Project = "MLP ICSARA"
    Owner   = "Modelamiento Numerico"
  }
}