# MODFLOW-AWS_PAR — Modelamiento Numérico Paralelo en AWS

Repositorio para la ejecución paralela de modelos MODFLOW-USG en AWS ECS Fargate. Cada task ejecuta el modelo de forma independiente con un conjunto de parámetros diferente, sin coordinación entre tasks.

## Índice

- [Descripción general](#descripción-general)
- [Arquitectura](#arquitectura)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos](#requisitos)
- [Flujo operacional completo](#flujo-operacional-completo)
  - [Fase 0: Preparación del modelo y parámetros](#fase-0-preparación-del-modelo-y-parámetros)
  - [Fase 1: Docker build y push a ECR](#fase-1-docker-build-y-push-a-ecr)
  - [Fase 2: Despliegue de infraestructura](#fase-2-despliegue-de-infraestructura)
  - [Fase 3: Ejecución de las corridas](#fase-3-ejecución-de-las-corridas)
  - [Fase 4: Respaldo de resultados](#fase-4-respaldo-de-resultados)
  - [Fase 5: Cierre de proyecto](#fase-5-cierre-de-proyecto)
- [Configuración por proyecto](#configuración-por-proyecto)
- [Referencia de comandos](#referencia-de-comandos)
- [Troubleshooting](#troubleshooting)
- [Notas para usuarios Mac (zsh)](#notas-para-usuarios-mac-zsh)

---

## Descripción general

Este sistema ejecuta modelos MODFLOW-USG en paralelo para análisis de incertidumbre. A diferencia de la calibración con PEST (repo `modflow-pest-calibracion`), aquí **no hay un master** que coordine. Cada task es completamente independiente:

1. Recibe un `ID_PARAMETRO` como variable de entorno
2. Lee el archivo de parámetros correspondiente (`params/param{ID}.par`)
3. Ejecuta el modelo con esos parámetros
4. Sube resultados a S3

Los archivos `.par` contienen conjuntos de parámetros que pasaron criterios de calibración previa. Están incluidos en la imagen Docker junto con el modelo. El archivo `calibrated_runs_*.txt` determina qué IDs ejecutar en cada corrida. Cada realización produce resultados independientes que, en conjunto, permiten cuantificar la incertidumbre en las predicciones.

**Comparación con PEST (`modflow-pest-calibracion`):**

| Aspecto | PEST (calibración) | Este repo (incertidumbre) |
|---------|-------------------|--------------------------|
| Coordinación | Master coordina agents via TCP | Sin coordinación, tasks independientes |
| Parámetros | PEST los calcula iterativamente | Pre-generados (archivos `.par`) |
| Resultados | Master consolida | Cada task sube directo a S3 |
| Auto-scaler | Lee logs del master | No necesario (se lanzan N tasks fijo) |
| Infraestructura | Service Discovery, VPC Endpoints | Solo ECS cluster + S3 |

## Arquitectura

```
                                                  ┌─────────────────┐
    ┌──────────┐                                  │  S3 - Resultados│
    │  ECR     │                                  │  /{proyecto}/   │
    │ (imagen) │                                  │   resultados/   │
    └────┬─────┘                                  └────────▲────────┘
         │                                                 │
    ┌────┴─────────────────────────────────────────────────┼────────┐
    │ ECS Cluster (Fargate)                                │        │
    │                                                      │        │
    │  ┌───────────────────┐  ┌───────────────────┐        │        │
    │  │ Task 1            │  │ Task 2            │        │        │
    │  │ ID_PARAMETRO=9    │  │ ID_PARAMETRO=10   │────────┘        │
    │  │                   │  │                   │                 │
    │  │ 1. Lee param9.par │  │ 1. Lee param10.par│                 │
    │  │ 2. Reemplaza .tpl │  │ 2. Reemplaza .tpl │                 │
    │  │ 3. MODFLOW-USG    │  │ 3. MODFLOW-USG    │                 │
    │  │ 4. Post-proceso   │  │ 4. Post-proceso   │                 │
    │  │ 5. Sube a S3      │  │ 5. Sube a S3      │                 │
    │  └───────────────────┘  └───────────────────┘                 │
    │                                                               │
    │  ┌───────────────────┐         ┌───────────────────┐          │
    │  │ Task 3            │   ...   │ Task N            │──────────┘
    │  │ ID_PARAMETRO=15   │         │ ID_PARAMETRO=995  │          │
    │  └───────────────────┘         └───────────────────┘          │ 
    │                                                               │
    └───────────────────────────────────────────────────────────────┘
         ▲
         │ auto_task_{proyecto}.py (máquina local)
         │ Lee lista de IDs desde .txt
         │ Lanza un ECS Task por cada ID
    ┌────┴────┐
    │ Laptop  │
    └─────────┘
```

**Flujo de ejecución dentro de cada task:**

```
Leer param{ID}.par → Reemplazar parámetros en templates → Ejecutar modelo → Subir resultados a S3
```

## Estructura del repositorio

```
MODFLOW-AWS_PAR/
├── Arquitectura/
│   └── Diseño de proceso MN..drawio        # Diagramas del proceso
│
├── ECS_task_execute/                        # Scripts de lanzamiento de tasks
│   ├── auto_task_{proyecto}.py              # Lanzador: lee .txt, lanza ECS tasks
│   ├── agente_{proyecto}_{region}.py        # Lanzador por región específica
│   ├── calibrated_runs_{proyecto}_{escenario}.txt  # IDs de parámetros a correr
│   └── requirements.txt                     # Dependencias Python del lanzador
│
├── IaC_terraform/                           # Infraestructura por región
│   ├── us-east-1/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── provider.tf
│   ├── us-east-2/
│   └── us-west-2/
│
├── Modelamiento/
│   └── numerico/
│       ├── agente_mpupio/                   # Imagen Docker: modelo Mpupio
│       │   ├── Dockerfile
│       │   ├── requirements.txt
│       │   └── app/
│       │       ├── main.py                  # Script de ejecución del modelo
│       │       ├── entrypoint.sh            # Entrypoint: main.py + upload S3
│       │       ├── run_calib_incert.py      # ...
│       │       ├── params/                  # Archivos .par (gitignored)
│       │       ├── model/                   # Archivos del modelo (gitignored)
│       │       └── resultados/              # Resultados locales (gitignored)
│       ├── agente_pelambres/                # Imagen Docker: modelo Pelambres
│       └── agente_choapa/                   # Imagen Docker: modelo Choapa
│
├── backup&delete/                           # Scripts de cierre de proyecto
│   ├── README.md                            # Procedimiento de cierre completo
│   ├── Backup_S3.ps1                        # Descargar buckets S3 a servidor local
│   ├── Download_ECR.ps1                     # Descargar imágenes Docker desde ECR
│   ├── Export_image_docker.ps1              # Exportar imágenes Docker a .tar
│   ├── Delete_buckets.ps1                   # Eliminar buckets S3
│   └── Delete_ecr.ps1                       # Eliminar repositorios ECR
│
├── requirements.txt
└── README.md
```

## Requisitos

### Software

| Herramienta | Versión mínima | Uso |
|-------------|---------------|-----|
| AWS CLI v2 | 2.x | Interacción con AWS |
| Terraform | 1.0+ | Crear/destruir infraestructura |
| Docker Desktop | 4.x | Build de imágenes |
| Python | 3.8+ | Scripts de lanzamiento |

### Dependencias Python

```bash
# Opción 1: pip
pip install -r requirements.txt

# Opción 2: uv (más rápido)
uv pip install -r requirements.txt
```

### Credenciales AWS

```bash
aws sts get-caller-identity
# Permisos necesarios: ECS, ECR, S3, IAM, EC2 (VPC/SG), CloudWatch Logs
```

---

## Flujo operacional completo

### Fase 0: Preparación del modelo y parámetros

**El especialista hidrogeólogo** entrega el modelo completo listo para ejecutar: archivos del modelo, carpeta `params/` con los `.par`, y el script de ejecución.

**El ingeniero de datos** recibe estos archivos y:

1. Los coloca en `Modelamiento/numerico/agente_{proyecto}/app/`
2. Ajusta `main.py` si el nuevo proyecto tiene diferencias (nombres de parámetros, cantidad de capas, archivos de salida)
3. Ajusta `entrypoint.sh` con el bucket S3 correcto:
   ```bash
   #!/bin/bash
   python3 /app/main.py
   aws s3 cp /app/resultados/ s3://<bucket>/resultados/ --recursive
   ```
4. Coloca el archivo `calibrated_runs_{proyecto}_{escenario}.txt` en `ECS_task_execute/` con los IDs a ejecutar (un ID por línea)

Los archivos `.par` y el modelo completo quedan baked en la imagen Docker al hacer el build.

### Fase 1: Docker build y push a ECR

```bash
cd Modelamiento/numerico/agente_{proyecto}/
```

**Crear repositorio ECR** (solo la primera vez):

<!-- tabs:start -->
#### **bash / zsh (Mac/Linux)**
```bash
aws ecr create-repository \
  --repository-name agente-{proyecto} \
  --region <region>
```

#### **PowerShell (Windows)**
```powershell
aws ecr create-repository `
  --repository-name agente-{proyecto} `
  --region <region>
```
<!-- tabs:end -->

**Build y push:**

<!-- tabs:start -->
#### **bash / zsh (Mac/Linux)**
```bash
# Build (en Mac ARM, siempre con --platform)
docker build --platform linux/amd64 \
  -t <account-id>.dkr.ecr.<region>.amazonaws.com/agente-{proyecto}:latest .

# Login ECR
aws ecr get-login-password --region <region> | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.<region>.amazonaws.com

# Push
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/agente-{proyecto}:latest
```

#### **PowerShell (Windows)**
```powershell
# Build
docker build -t <account-id>.dkr.ecr.<region>.amazonaws.com/agente-{proyecto}:latest .

# Login ECR
aws ecr get-login-password --region <region> | `
  docker login --username AWS --password-stdin `
  <account-id>.dkr.ecr.<region>.amazonaws.com

# Push
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/agente-{proyecto}:latest
```
<!-- tabs:end -->

### Fase 2: Despliegue de infraestructura

```bash
cd IaC_terraform/<region>/

# Editar variables.tf con los valores del proyecto
terraform init
terraform plan
terraform apply
```

**Qué crea Terraform:**
- ECS Cluster + Task Definition (un solo tipo de task, sin master)
- IAM Roles (execution role, task role con acceso a S3 y CloudWatch)
- Security Groups
- CloudWatch Log Group
- (Nota: no se necesitan VPC Endpoints ni Service Discovery)

### Fase 3: Ejecución de las corridas

**Ajustar el script de lanzamiento** (`ECS_task_execute/auto_task_{proyecto}.py`):

```python
# Valores a configurar en el script:
cluster_name = 'cluster-agente-{proyecto}'
task_definition = 'task-agente-{proyecto}'
subnet_id = '<subnet-id>'
security_group_id = '<sg-id>'
container_name = 'agente-{proyecto}'  # Nombre del container en la task definition
region = '<region>'
```

**Ejecutar el lanzador:**

```bash
cd ECS_task_execute/

# Activar entorno virtual
python -m venv .venv
source .venv/bin/activate       # Mac/Linux
# .venv\Scripts\activate        # Windows

pip install -r requirements.txt

# Lanzar las corridas
python auto_task_{proyecto}.py
```

El script:
1. Lee la lista de IDs desde `calibrated_runs_{proyecto}_{escenario}.txt` (o usa un `range()` para corridas secuenciales)
2. Por cada ID, lanza un ECS Task con `ID_PARAMETRO` como variable de entorno
3. Espera 0.2s entre lanzamientos para no saturar la API
4. Si un lanzamiento falla, reintenta después de 30s

**Monitorear progreso:**

<!-- tabs:start -->
#### **bash / zsh (Mac/Linux)**
```bash
# Contar tasks activos
aws ecs list-tasks \
  --cluster cluster-agente-{proyecto} \
  --desired-status RUNNING \
  --region <region> \
  --query "length(taskArns)" --output text

# Ver logs recientes
aws logs tail /ecs/agente-{proyecto} --region <region> --since 30m
```

#### **PowerShell (Windows)**
```powershell
# Contar tasks activos
aws ecs list-tasks `
  --cluster cluster-agente-{proyecto} `
  --desired-status RUNNING `
  --region <region> `
  --query "length(taskArns)" --output text
```
<!-- tabs:end -->

### Fase 4: Respaldo de resultados

Los resultados se suben automáticamente a S3 desde cada task. Para descargarlos localmente:

<!-- tabs:start -->
#### **bash / zsh (Mac/Linux)**
```bash
# Descargar resultados de un proyecto
mkdir -p respaldo_{proyecto}_$(date +%Y%m%d)
aws s3 sync s3://<bucket>/resultados/ respaldo_{proyecto}_$(date +%Y%m%d)/ --region <region>
```

#### **PowerShell (Windows)**
```powershell
# Descargar todos los buckets del proyecto
# Ajustar la lista de buckets en Backup_S3.ps1
cd backup&delete
.\Backup_S3.ps1
```
<!-- tabs:end -->

### Fase 5: Cierre de proyecto

Cuando el proyecto finaliza, seguir este procedimiento en orden. **Todo paso es irreversible una vez ejecutado.**

#### Paso 1: Confirmar cierre

El equipo de infraestructura confirma por correo con el equipo y/o PM la finalización del proyecto.

#### Paso 2: Respaldar resultados S3

Descargar todos los buckets del proyecto al servidor on-premise o máquina local.

**Estructura de respaldo en servidor CDFLOW:**
```
D:\20_AWS\{nombre_proyecto}\S3\{nombre-bucket}
D:\20_AWS\{nombre_proyecto}\ECR\{nombre-repo}
```

<!-- tabs:start -->
#### **bash / zsh (Mac/Linux)**
```bash
# Para cada bucket del proyecto:
BUCKETS=("<account-id>-agente-{proyecto}" "<account-id>-agente-{proyecto}-cb" "<account-id>-agente-{proyecto}-evu")

for bucket in "${BUCKETS[@]}"; do
  echo "Descargando bucket: $bucket"
  mkdir -p "$bucket"
  aws s3 cp "s3://$bucket" "./$bucket" --recursive
done
```

#### **PowerShell (Windows)**
```powershell
# Ajustar la lista de buckets en Backup_S3.ps1
cd backup&delete
.\Backup_S3.ps1
```
<!-- tabs:end -->

#### Paso 3: Respaldar imágenes Docker desde ECR

<!-- tabs:start -->
#### **bash / zsh (Mac/Linux)**
```bash
REGION="<region>"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Login ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_URL

# Descargar todas las imágenes de la región
REPOS=$(aws ecr describe-repositories --region $REGION \
  --query 'repositories[*].repositoryName' --output text)

for repo in $REPOS; do
  echo "Descargando: $ECR_URL/$repo:latest"
  docker pull "$ECR_URL/$repo:latest"
  # Exportar a .tar
  docker save -o "${repo}.tar" "$ECR_URL/$repo:latest"
  echo "Exportado: ${repo}.tar"
done
```

#### **PowerShell (Windows)**
```powershell
# Paso 1: Descargar imágenes
aws ecr get-login-password --region <region> | `
  docker login --username AWS --password-stdin `
  <account-id>.dkr.ecr.<region>.amazonaws.com

cd backup&delete
.\Download_ECR.ps1

# Paso 2: Exportar a .tar
# Ajustar la lista de imágenes en Export_image_docker.ps1
.\Export_image_docker.ps1
```
<!-- tabs:end -->

#### Paso 4: Destruir infraestructura con Terraform

```bash
cd IaC_terraform/<region>/
terraform plan     # Verificar estado actual
terraform destroy  # Eliminar recursos
```

#### Paso 5: Eliminar recursos creados manualmente (S3 y ECR)

Terraform no elimina recursos creados fuera de su state (buckets S3 y repos ECR creados manualmente).

<!-- tabs:start -->
#### **bash / zsh (Mac/Linux)**
```bash
# Eliminar buckets S3
BUCKETS=("<account-id>-agente-{proyecto}" "<account-id>-agente-{proyecto}-cb")

for bucket in "${BUCKETS[@]}"; do
  echo "Eliminando bucket: $bucket"
  aws s3 rm "s3://$bucket" --recursive
  aws s3api delete-bucket --bucket "$bucket"
done

# Eliminar repos ECR
REGION="<region>"
REPOS=("agente-{proyecto}" "agente-{proyecto}-cb")

for repo in "${REPOS[@]}"; do
  echo "Eliminando repo ECR: $repo"
  aws ecr delete-repository --region $REGION --repository-name "$repo" --force
done
```

#### **PowerShell (Windows)**
```powershell
# Ajustar listas en cada script
cd backup&delete
.\Delete_buckets.ps1
.\Delete_ecr.ps1
```
<!-- tabs:end -->

---

## Configuración por proyecto

### Variables de Terraform (`variables.tf`)

```hcl
variable "project_name"    { default = "<nombre-proyecto>" }     # Ej: "agente-mpupio"
variable "aws_region"      { default = "<region>" }              # Ej: "us-east-1"
variable "vpc_id"          { default = "<vpc-id>" }
variable "subnet_ids"      { default = ["<subnet-1>"] }
variable "ecr_image"       { default = "<account-id>.dkr.ecr.<region>.amazonaws.com/agente-<proyecto>:latest" }
variable "s3_bucket"       { default = "<account-id>-agente-<proyecto>" }
```

### Convención de nombres

| Recurso | Formato |
|---------|---------|
| Cluster ECS | `cluster-agente-{proyecto}` |
| Task Definition | `task-agente-{proyecto}` |
| Container | `agente-{proyecto}` |
| Bucket S3 | `<account-id>-agente-{proyecto}[-escenario]` |
| Repo ECR | `agente-{proyecto}[-escenario]` |
| Log Group | `/ecs/agente-{proyecto}` |

### Escenarios por proyecto

Los proyectos pueden tener múltiples escenarios, cada uno con su propio bucket S3 e imagen Docker:

| Sufijo | Significado |
|--------|-------------|
| (sin sufijo) | Escenario base |
| `-cb` | Caso base |
| `-evu` | Evaluación |
| `-cb-cierre` | Caso base cierre |
| `-evu-cierre` | Evaluación cierre |
| `-cb-op` | Caso base operación |
| `-evu-op` | Evaluación operación |

### Proyectos

| Proyecto | Cliente | Regiones | Escenarios |
|----------|---------|----------|------------|
| mpupio | SQM | us-east-1, us-west-2 | base, cb, evu |
| pelambres | Pelambres | us-east-1, us-east-2 | cb-cierre, cb-op, evu-cierre, evu-op |
| choapa | Choapa | us-east-1 | base, cb, evu |

---

## Referencia de comandos

### ECR

| Acción | Comando |
|--------|---------|
| Crear repo | `aws ecr create-repository --repository-name agente-{proyecto} --region <region>` |
| Login | `aws ecr get-login-password --region <region> \| docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com` |
| Build (Mac ARM) | `docker build --platform linux/amd64 -t <account-id>.dkr.ecr.<region>.amazonaws.com/agente-{proyecto}:latest .` |
| Push | `docker push <account-id>.dkr.ecr.<region>.amazonaws.com/agente-{proyecto}:latest` |
| Listar repos | `aws ecr describe-repositories --region <region> --query 'repositories[*].repositoryName' --output table` |

### ECS

| Acción | Comando |
|--------|---------|
| Listar tasks | `aws ecs list-tasks --cluster cluster-agente-{proyecto} --region <region>` |
| Contar RUNNING | `aws ecs list-tasks --cluster cluster-agente-{proyecto} --desired-status RUNNING --region <region> --query "length(taskArns)" --output text` |
| Ver task detail | `aws ecs describe-tasks --cluster cluster-agente-{proyecto} --tasks <task-arn> --region <region>` |

### S3

| Acción | Comando |
|--------|---------|
| Descargar resultados | `aws s3 sync s3://<bucket>/resultados/ . --region <region>` |
| Listar resultados | `aws s3 ls s3://<bucket>/resultados/ --region <region>` |
| Contar archivos | `aws s3 ls s3://<bucket>/resultados/ --region <region> --recursive \| wc -l` |

### Docker

| Acción | Comando |
|--------|---------|
| Limpiar imágenes | `docker image prune -a` |
| Limpiar build cache | `docker builder prune -f` |
| Exportar imagen a .tar | `docker save -o agente-{proyecto}.tar <imagen>` |
| Importar imagen desde .tar | `docker load -i agente-{proyecto}.tar` |

---

## Troubleshooting

### Task falla inmediatamente (STOPPED con exit code 1)

Verificar que `ID_PARAMETRO` está configurado y que el archivo `.par` correspondiente existe en la imagen Docker:

```bash
# Ver razón de fallo
aws ecs describe-tasks \
  --cluster cluster-agente-{proyecto} \
  --tasks <task-arn> \
  --region <region> \
  --query "tasks[0].stoppedReason"
```

### "ID_PARAMETRO no asignado"

El task se lanzó sin la variable de entorno. Verificar que el script de lanzamiento pasa `ID_PARAMETRO` en `containerOverrides.environment`.

### API rate limit al lanzar muchos tasks

El script `auto_task_*.py` tiene un retry con espera de 30 segundos. Si persiste, aumentar el `time.sleep()` entre lanzamientos.

### Resultados no aparecen en S3

1. Verificar que el `entrypoint.sh` tiene el bucket correcto
2. Verificar que el task role tiene permisos `s3:PutObject` en el bucket
3. Verificar logs del task para errores en `aws s3 cp`

### Docker build falla en Mac

Asegurarse de usar `--platform linux/amd64`:
```bash
docker build --platform linux/amd64 -t agente-{proyecto} .
```

### Wine muestra warnings o errores

Es normal ver warnings de Wine sobre display. Si el modelo no corre, verificar que los ejecutables están en la carpeta `model/` y son compatibles con Wine.

---

## Notas para usuarios Mac (zsh)

### Docker en Apple Silicon (M1/M2/M3)

Fargate requiere imágenes `linux/amd64`. Siempre usar:
```bash
docker build --platform linux/amd64 -t agente-{proyecto} .
```

### Scripts de backup&delete

Los scripts en `backup&delete/` son PowerShell. Equivalentes en bash:

```bash
# Backup de buckets (equivalente a Backup_S3.ps1)
for bucket in bucket1 bucket2 bucket3; do
  mkdir -p "$bucket"
  aws s3 cp "s3://$bucket" "./$bucket" --recursive
done

# Descargar imágenes ECR (equivalente a Download_ECR.ps1 + Export_image_docker.ps1)
REGION="<region>"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ECR="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR

for repo in $(aws ecr describe-repositories --region $REGION --query 'repositories[*].repositoryName' --output text); do
  docker pull "$ECR/$repo:latest"
  docker save -o "${repo}.tar" "$ECR/$repo:latest"
done

# Eliminar buckets (equivalente a Delete_buckets.ps1)
for bucket in bucket1 bucket2; do
  aws s3 rm "s3://$bucket" --recursive
  aws s3api delete-bucket --bucket "$bucket"
done

# Eliminar repos ECR (equivalente a Delete_ecr.ps1)
for repo in repo1 repo2; do
  aws ecr delete-repository --region $REGION --repository-name "$repo" --force
done
```

---

## Archivos auxiliares

### `run_calib_incert.py`

Versión local?

### `ECS_task_execute/regex.py`

Script auxiliar para procesar resultados o logs con expresiones regulares.

---

**Branches**: `main`  
**Última actualización**: Febrero 2026