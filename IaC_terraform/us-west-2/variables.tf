variable "aws_region" {
  default = "us-west-2"
}

variable "ID_PARAMETRO" {
  description = "ID de parámetro para el modelo"
  type        = string
  default     = "0"
}

variable "ecr_image_mpupio" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-west-2.amazonaws.com/agente-mpupio:latest"
}

variable "ecr_image_mpupio_cb" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-west-2.amazonaws.com/agente-mpupio-cb:latest"
}

variable "ecr_image_mpupio_evu" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-west-2.amazonaws.com/agente-mpupio-evu:latest"
}

variable "ecr_image_choapa" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-west-2.amazonaws.com/agente-choapa:latest"
}

variable "ecr_image_choapa_cb" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-west-2.amazonaws.com/agente-choapa-cb:latest"
}

variable "ecr_image_choapa_evu" {
  description = "Imagen del contenedor"
  type        = string
  default     = "312019940349.dkr.ecr.us-west-2.amazonaws.com/agente-choapa-evu:latest"
}

variable "common_tags_icsara" {
  type = map(string)
  default = {
    Region  = "us-west-2"
    Service = "FARGATE"
    Project = "MLP ICSARA"
    Owner   = "Modelamiento Numerico"
  }
}