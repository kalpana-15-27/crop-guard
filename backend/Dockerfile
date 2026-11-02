# CropGuard AI — Production Dockerfile for FastAPI + YOLO11s Inference Backend
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for OpenCV and image operations
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY backend/requirements.txt requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code and trained YOLO model weights
COPY backend/app ./app
COPY backend/run.py .
COPY ml/weights/best.pt ./ml/weights/best.pt

EXPOSE 8000

ENV HOST=0.0.0.0
ENV PORT=8000
ENV MODEL_PATH=/app/ml/weights/best.pt
ENV PYTHONPATH=/app

CMD ["python", "run.py"]
