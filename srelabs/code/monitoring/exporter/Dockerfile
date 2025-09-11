# exporter/Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY nginx_exporter.py /app/nginx_exporter.py

RUN pip install --no-cache-dir flask requests

EXPOSE 9113

CMD ["python", "/app/nginx_exporter.py"]

