# PROCEDIMIENTO DE CIERRE DE PROYECTO EN AWS

Aquí se define el procedimiento a realizar para la finalización y cierre de un proyecto de procesamiento en AWS. Esto puede ser antes de la entrega final al cliente.

## PASO 01

Equipo de Infraestructura TI debe confirmar mediante correo electrónico con Equipo y/o PM la finalización y el cierre del proyecto en AWS.

## PASO 02

Equipo de Infreaestrucutra debe realizar un catastro de recursos y definir los respaldos necesarios, se ha establecido que el respaldo se realizará en servidor on-premise CDFLOW y se ha definido la siguiente ruta y estructura de respaldo:

- Ruta base en servidor CDFLOW:  D:\20_AWS
- Nombre del proyecto
- recurso a respaldar
- nombre del recurso a respaldar

Por ejemplo, para respaldar el bucket de S3 con nombre "312019940349-agente-choapa" del proyecto MLP ICSARA su ruta de respaldo será:

- D:\20_AWS\MLP_ICSARA\S3\312019940349-agente-choapa

Por ejemplo, para respaldar la imagen docker del modelo mpupio con nombre "agente-mpupio" del proyecto MLP ICSARA su ruta de respaldo será:

- D:\20_AWS\MLP_ICSARA\ECR\agente-mpupio

## PASO 03 RESPALDO DE RESULTADOS Y RECURSOS UTILIZADOS

El equipo de infraestructura debe proceder con el respado de resultados y recursos utilizados en la nube de AWS

Se ha generado un script por tipo de recurso que se ejecutará en el servidor on-premise CDFLOW.

**Requisitos previos:**
Tener AWS CLI Instalado y configurado (aws configure)
Abrir PowerShell como Administrador.
Si es necesario, permitir la ejecución de scripts (solo una vez):
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

### Respaldos S3

Guarda el script como Backup_S3.ps1 en la carpeta donde realizará el respaldo.

**Nota:** ajuste el listado de buckets en cada script

Ejecutar el script en PowerShell:
.\Backup_S3.ps1

### Respaldos ECR

Se realiza en 2 pasos, primero se descarga con docker  y luego se exporta la imagen a un archivo .tar

Guarde el script Download_ECR.ps1 en carpeta donde se almacenarán las imágenes docker.
**Nota:** ajuste la región en el script

Conecte su docker a la misma región del script en AWS para realizar la descarga:

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 312019940349.dkr.ecr.us-east-1.amazonaws.com

Ejecutar el script para realizar la descarga de todas las imágenes de la región, considera tener espacio suficiente.
.\Download_ECR.ps1

Guarde el script Export_image_docker.ps1 en carpeta donde se almacenarán las imágenes docker.
Modifique la variable $imagenes con todas las imágenes que se han descargado.
Ejecutar el script
.\Export_image_docker.ps1

## PASO 04 ELIMINAR INFRAESTRUCTURA CON TERRAFORM

Eliminar recursos usando los camandos de terraform

**Requisitos previos:**
Descargar Terraform y agregar ruta de terraform a variable de entorno Path de Windows, para que la consola reconozca los comandos de terraform.

Verificar que el estado actual es igual a la infraestructura en la nube AWS:
Terraform plan

Eliminar los recursos, ejecutar:
Terraform destroy

Eliminar la infraestructura generada manualmente, en el caso de MLP ICSARA corresponde a recursos S3 y ECR creados manualmente.

### ELIMINAR RECURSOS S3

Descargue el script Delete_buckets.ps1
**nota:** Ajuste el listado de buckets a eliminar

Ejecutar el script
.\Delete_buckets.ps1

### ELIMINAR RECURSOS ECR

Descargue el script Delete_ecr.ps1
**nota:** Ajuste el listado de repositorios ECR a eliminar

Ejecutar el script
.\Delete_ecr.ps1