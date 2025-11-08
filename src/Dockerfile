FROM python:3.12-slim

WORKDIR /app

# Copy dependency manifest and install Python deps
# Note: when building the image from repo root use: docker build -f src/Dockerfile .
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy only the application source (we keep project root files out of the image)
COPY src/ /app/

# Create a non-root user and give ownership of the app directory
RUN useradd -m appuser \
 && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Run the FastAPI app. main.py is under /app/main.py and defines `app`.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
