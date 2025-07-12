# Región AWS
$region = "us-east-1"  # Cambia según tu región

# Lista de repositorios ECR a eliminar
$repositorios = @(
    "agente-choapa",
    "agente-choapa-cb",
    "agente-choapa-evu",
    "agente-mpupio",
    "agente-mpupio-cb",
    "agente-mpupio-evu",
    "agente-pelambres",
    "agente-pelambres-cb-cierre",
    "agente-pelambres-cb-op",
    "agente-pelambres-evu-cierre",
    "agente-pelambres-evu-op"
)

foreach ($repo in $repositorios) {
    Write-Host "Verificando si existe el repositorio: $repo"

    $exists = $false
    try {
        aws ecr describe-repositories --region $region --repository-names $repo | Out-Null
        $exists = $true
    } catch {
        Write-Host "Repositorio $repo no existe. Saltando..."
    }

    if ($exists) {
        Write-Host "Eliminando imágenes del repositorio: $repo"

        # Obtener los digests de las imágenes
        $digests = aws ecr list-images --region $region --repository-name $repo --query 'imageIds[*].imageDigest' --output text
        $digests = $digests -split "\s+"

        foreach ($digest in $digests) {
            if ($digest -ne "") {
                aws ecr batch-delete-image --region $region --repository-name $repo --image-ids imageDigest=$digest | Out-Null
            }
        }

        # Eliminar el repositorio
        Write-Host "$region Eliminando repositorio: $repo"
        aws ecr delete-repository --region $region --repository-name $repo --force
        Write-Host "$region Repositorio eliminado: $repo"
    }
}

Write-Host "Proceso finalizado."