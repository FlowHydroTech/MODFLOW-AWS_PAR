# MODFLOW-AWS_PAR

Este proyecto permite ejecutar modelos MODFLOW en AWS ECS usando Docker, Terraform y scripts de automatización en Python.

## Estructura del proyecto

```
MODFLOW-AWS_PAR/
├── .gitignore
├── README.md
├── Arquitectura/
│   └── Diseño de proceso MN..drawio
├── ECS_task_execute/
│   ├── auto_task_choapa.py
│   ├── auto_task_mpupio_cb.py
│   ├── auto_task_mpupio_evu.py
│   ├── auto_task_mpupio.py
│   ├── auto_task_pelambres.py
│   ├── agente_pelambres_cb_op_p1_east_1.py
│   ├── agente_pelambres_cb_op_p2_east_2.py
│   ├── agente_pelambres_evu_op_p1_east_1.py
│   ├── agente_pelambres_evu_op_p2_east_2.py
│   ├── calibrated_runs_mpupio_cb.txt
│   ├── calibrated_runs_mpupio_evu.txt
│   ├── ComandosDockerToAWS_ECR.txt
│   └── requirements.txt
├── IaC_terraform/
│   ├── us-east-1/
│   └── us-east-2/
└── Modelamiento/
    └── numerico/
```

## Requisitos

- Docker
- AWS CLI v2
- Terraform
- Python 3.x
- Paquetes Python (ver `ECS_task_execute/requirements.txt`)
- Permisos en AWS para ECR, ECS, S3, IAM

## Flujo de trabajo

### 1. Construir la imagen Docker

```sh
docker build -t agente_mpupio .
```

### 2. Crear repositorio en AWS ECR

```sh
aws ecr create-repository --repository-name agente_mpupio --region us-east-1
```

### 3. Autenticarse en ECR

```sh
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 312019940349.dkr.ecr.us-east-1.amazonaws.com
```

### 4. Etiquetar y subir la imagen

```sh
docker tag agente_mpupio:latest 312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-mpupio:latest
docker push 312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-mpupio:latest
```

### 5. Desplegar infraestructura con Terraform

```sh
cd IaC_terraform/us-east-1
terraform init
terraform apply
```

### 6. Ejecutar tareas ECS desde Python, Activar entorno virtual Python e instalar requirements.txt

```sh
cd ECS_task_execute
python auto_task_mpupio_cb.py
```

## Notas

- Los scripts Python leen archivos de parámetros (`calibrated_runs_mpupio_cb.txt`, etc.) y lanzan tareas ECS con diferentes variables de entorno.
- Los contenedores suben resultados a S3 al finalizar.
- Consulta `ECS_task_execute/ComandosDockerToAWS_ECR.txt` para más detalles de comandos Docker y ECR.

## Seguridad

**No compartas tus credenciales AWS.**  
Asegúrate de rotar claves si han sido expuestas.

---