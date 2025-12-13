# --- Stage 1: The Workshop (Builder) ---
FROM python:3.9 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# --- Stage 2: The Apartment (Runtime) ---
FROM python:3.9-slim
WORKDIR /app
# Copy only the installed artifacts
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
