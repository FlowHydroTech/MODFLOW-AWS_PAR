$region = "us-east-1"  # Cambia a tu región
$accountId = (aws sts get-caller-identity --query Account --output text)
$ecrUrl = "$accountId.dkr.ecr.$region.amazonaws.com"

# Obtener todos los repositorios
$repos = aws ecr describe-repositories --region $region --query 'repositories[*].repositoryName' --output text
$repos = $repos -split "\s+"

foreach ($repo in $repos) {
    Write-Host "Procesando repositorio: $repo"

    # Obtener todas las imágenes por tag (puede cambiarse a digest si lo prefieres)
    $tags = aws ecr list-images --repository-name $repo --region $region --query 'imageIds[*].imageTag' --output text
    $tags = $tags -split "\s+"

    foreach ($tag in $tags) {
        if ($tag -ne $null -and $tag -ne "") {
            $image = "$ecrUrl/${repo}:$tag"
            Write-Host "Descargando imagen: $image"
            docker pull $image
        }
    }
}

Write-Host "Descarga completa de todas las imágenes ECR en $region."