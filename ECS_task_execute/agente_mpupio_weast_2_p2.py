import boto3
import time
from datetime import datetime

# Parámetros básicos
cluster_name = 'cluster-agente-mpupio'
task_definition = 'task-agente-mpupio'
launch_type = 'FARGATE'  # Cambia a 'EC2' si no usas Fargate
subnet_id = 'subnet-0168d7d8961145483'  # Reemplaza con tu subnet real
security_group_id = 'sg-041eeccb0f1acb5c2'  # Reemplaza con tu grupo de seguridad


# Crear cliente ECS
ecs_client = boto3.client('ecs', region_name='us-east-1')  # Cambia a tu región

# Ejecutar 500 tareas
for i in range(501, 1001):
    while True:
        response = ecs_client.run_task(
        cluster=cluster_name,
        launchType=launch_type,
        count=1,
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': [subnet_id],
                'securityGroups': [security_group_id],
                'assignPublicIp': 'ENABLED'
            }
        },
        overrides={
            'containerOverrides': [
                {
                    'name': 'agente-mpupio',  # Reemplaza con el nombre dentro de la definición de tarea
                    'environment': [
                        {'name': 'ID_PARAMETRO', 'value': str(i)}
                    ]
                }
            ]
        },
        taskDefinition=task_definition
        )

        try:
            print(f"{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} Tarea {i} ejecutada, ARN: {response['tasks'][0]['taskArn']}")
            time.sleep(0.2)  # Evita golpear el API con demasiadas peticiones por segundo
            break  # Salir del bucle si la tarea se ejecutó correctamente
        except Exception as e:
            print(f"{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} Error al ejecutar la tarea {i}: {response['failures'][0]['reason']}")
            print(f"{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} reintentando en 30 segundos...")
            # Espera para evitar sobrecargar el API de ECS
            time.sleep(30)  # Espera 30 segundos antes de reintentar

print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} Las {i} tareas han sido enviadas.")