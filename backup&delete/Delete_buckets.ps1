# Lista de buckets a eliminar
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
    Write-Host "Eliminando contenido del bucket: $bucket"
    aws s3 rm "s3://$bucket" --recursive

    Write-Host "Eliminando bucket: $bucket"
    aws s3api delete-bucket --bucket $bucket

    Write-Host "Bucket $bucket eliminado."
}

Write-Host "Todos los buckets han sido eliminados correctamente."