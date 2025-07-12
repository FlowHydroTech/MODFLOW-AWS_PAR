# Lista de buckets
$buckets = @(
    "312019940349-agente-choapa",
    "312019940349-agente-choapa-cb",
    "312019940349-agente-choapa-evu",
    "312019940349-agente-mpupio",
    "312019940349-agente-mpupio-cb",
    "312019940349-agente-mpupio-evu",
    "312019940349-agente-pelambres",
    "312019940349-agente-pelambres-cb-cierre",
    "312019940349-agente-pelambres-cb-op",
    "312019940349-agente-pelambres-evu-cierre",
    "312019940349-agente-pelambres-evu-op"
)

foreach ($bucket in $buckets) {
    Write-Host "Descargando bucket: $bucket"
    
    $localPath = ".\$bucket"
    if (-Not (Test-Path $localPath)) {
        New-Item -ItemType Directory -Path $localPath | Out-Null
    }

    aws s3 cp "s3://$bucket" $localPath --recursive
}

Write-Host "Todos los buckets han sido descargados."