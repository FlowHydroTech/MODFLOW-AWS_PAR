#!/bin/bash
python3 /app/main.py
aws s3 cp /app/resultados/ s3://312019940349-agente-pelambres/resultados/ --recursive