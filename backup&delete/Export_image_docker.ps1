# Lista de imágenes Docker (pueden venir de ECR u otro repositorio)
$imagenes = @(
    "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-choapa",
    "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-choapa-cb",
    "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-choapa-evu",
    "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-mpupio",
    "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-pelambres",
    "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-pelambres-cb-cierre",
    "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-pelambres-cb-op",
    "312019940349.dkr.ecr.us-east-1.amazonaws.com/agente-pelambres-evu-op",
    "312019940349.dkr.ecr.us-east-2.amazonaws.com/agente-pelambres-evu-cierre",
    "312019940349.dkr.ecr.us-west-2.amazonaws.com/agente-mpupio-cb",
    "312019940349.dkr.ecr.us-west-2.amazonaws.com/agente-mpupio-evu"
)

foreach ($imagen in $imagenes) {
    Write-Host "Procesando imagen: $imagen"

    # Obtener solo el nombre final para usar como nombre del archivo
    $nombre = ($imagen -split "/")[-1] + ".tar"

    # Exportar la imagen como .tar
    docker save -o $nombre $imagen

    Write-Host "Exportada como: $nombre"
}