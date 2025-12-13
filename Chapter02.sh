#!/bin/bash

# ==============================================================================
# DockerDelta - Chapter 2: Orchestration Setup
# Theme: The EV Rental Agent (Modular Monolith)
# ==============================================================================

BASE_DIR="./02_orchestration/ev_rental_agent"
echo "📂 Creating Chapter 2 Project (EV Agent) in: $BASE_DIR"

mkdir -p "$BASE_DIR/config"
mkdir -p "$BASE_DIR/ev_app/migrations"
mkdir -p "$BASE_DIR/ev_app/management/commands"
mkdir -p "$BASE_DIR/templates"
mkdir -p "$BASE_DIR/static/js"
mkdir -p "$BASE_DIR/data"

# 1. Configuration Files
cat > "$BASE_DIR/requirements.txt" <<EOF
Django>=5.0,<6.0
psycopg2-binary
dspy-ai
google-generativeai
python-dotenv
EOF

cat > "$BASE_DIR/.env" <<EOF
DEBUG=True
SECRET_KEY=django-insecure-master-key-change-in-prod
DATABASE_URL=postgres://postgres:password@db:5432/ev_app
ALLOWED_HOSTS=localhost,127.00.0.1,0.0.0.0
# REPLACE THIS WITH YOUR REAL KEY
GEMINI_API_KEY=
EOF

cat > "$BASE_DIR/Dockerfile" <<'EOF'
FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /app
RUN apt-get update && apt-get install -y netcat-openbsd gcc && rm -rf /var/lib/apt/lists/*
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt
COPY . /app/
# Rootless Setup
RUN adduser --disabled-password --gecos '' --uid 1000 appuser
RUN chown -R appuser:appuser /app
USER appuser
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
EOF

cat > "$BASE_DIR/docker-compose.yml" <<'EOF'
version: '3.8'
services:
  web:
    build: .
    container_name: ev_agent_web
    volumes:
      - .:/app
      - ./data:/app/data
    ports: ["8000:8000"]
    env_file: .env
    depends_on:
      - db
    command: sh entrypoint.sh
  db:
    image: postgres:16
    container_name: ev_agent_db
    volumes:
      - pg_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ev_app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
volumes:
  pg_data:
EOF

cat > "$BASE_DIR/entrypoint.sh" <<'EOF'
#!/bin/sh
echo "Waiting for postgres..."
while ! nc -z db 5432; do sleep 0.1; done
echo "PostgreSQL started"
python manage.py makemigrations ev_app
python manage.py migrate
python manage.py load_inventory
exec python manage.py runserver 0.0.0.0:8000
EOF
chmod +x "$BASE_DIR/entrypoint.sh"

# 2. Django Core Files
cat > "$BASE_DIR/manage.py" <<'EOF'
#!/usr/bin/env python
import os
import sys
def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError("Couldn't import Django.") from exc
    execute_from_command_line(sys.argv)
if __name__ == '__main__':
    main()
EOF
chmod +x "$BASE_DIR/manage.py"

touch "$BASE_DIR/config/__init__.py"
cat > "$BASE_DIR/config/wsgi.py" <<'EOF'
import os
from django.core.wsgi import get_wsgi_application
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
application = get_wsgi_application()
EOF

cat > "$BASE_DIR/config/urls.py" <<'EOF'
from django.contrib import admin
from django.urls import path, include
urlpatterns = [path('admin/', admin.site.urls), path('', include('ev_app.urls'))]
EOF

cat > "$BASE_DIR/config/settings.py" <<'EOF'
from pathlib import Path
import os
import dspy
BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-test-key')
DEBUG = os.environ.get('DEBUG', 'True') == 'True'
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(',')
INSTALLED_APPS = ['django.contrib.admin', 'django.contrib.auth', 'django.contrib.contenttypes', 'django.contrib.sessions', 'django.contrib.messages', 'django.contrib.staticfiles', 'ev_app']
MIDDLEWARE = ['django.middleware.security.SecurityMiddleware', 'django.contrib.sessions.middleware.SessionMiddleware', 'django.middleware.common.CommonMiddleware', 'django.middleware.csrf.CsrfViewMiddleware', 'django.contrib.auth.middleware.AuthenticationMiddleware', 'django.contrib.messages.middleware.MessageMiddleware', 'django.middleware.clickjacking.XFrameOptionsMiddleware']
ROOT_URLCONF = 'config.urls'
TEMPLATES = [{'BACKEND': 'django.template.backends.django.DjangoTemplates', 'DIRS': [BASE_DIR / 'templates'], 'APP_DIRS': True, 'OPTIONS': {'context_processors': ['django.template.context_processors.debug', 'django.template.context_processors.request', 'django.contrib.auth.context_processors.auth', 'django.contrib.messages.context_processors.messages']}}]
WSGI_APPLICATION = 'config.wsgi.application'
DATABASES = {'default': {'ENGINE': 'django.db.backends.postgresql', 'NAME': os.environ.get('POSTGRES_DB', 'ev_app'), 'USER': os.environ.get('POSTGRES_USER', 'postgres'), 'PASSWORD': os.environ.get('POSTGRES_PASSWORD', 'password'), 'HOST': 'db', 'PORT': '5432'}}
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True
STATIC_URL = 'static/'
STATICFILES_DIRS = [BASE_DIR / "static"]
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if GEMINI_API_KEY:
    try:
        lm = dspy.LM('gemini/gemini-2.5-flash-preview-09-2025', api_key=GEMINI_API_KEY)
        dspy.configure(lm=lm)
    except: pass
EOF

# 3. App Logic
touch "$BASE_DIR/ev_app/__init__.py"
cat > "$BASE_DIR/ev_app/models.py" <<'EOF'
from django.db import models
from django.contrib.auth.models import User
class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=100, blank=True, null=True)
    nickname = models.CharField(max_length=50, blank=True, null=True)
    license_id = models.CharField(max_length=50, blank=True, null=True)
class EVCar(models.Model):
    model_name = models.CharField(max_length=100)
    range_km = models.IntegerField()
    price_per_day = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, default='AVAILABLE')
class Transaction(models.Model):
    customer = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    car = models.ForeignKey(EVCar, on_delete=models.CASCADE)
    type = models.CharField(max_length=20)
    status = models.CharField(max_length=20, default='DRAFT')
    created_at = models.DateTimeField(auto_now_add=True)
EOF

cat > "$BASE_DIR/ev_app/dspy_agent.py" <<'EOF'
import dspy
from .models import UserProfile, EVCar, Transaction
from django.contrib.auth.models import User
import json
def search_cars(query_str: str = "") -> str:
    cars = EVCar.objects.filter(status='AVAILABLE')
    if query_str: cars = cars.filter(model_name__icontains=query_str)
    return "\n".join([f"{c.model_name} (${c.price_per_day}/day)" for c in cars]) if cars.exists() else "No cars found."
class EVSignature(dspy.Signature):
    """EV Consultant Agent."""
    chat_history = dspy.InputField()
    user_query = dspy.InputField()
    response = dspy.OutputField()
class EVAgent(dspy.Module):
    def __init__(self):
        super().__init__()
        self.prog = dspy.ChainOfThought(EVSignature)
    def forward(self, history, query):
        return self.prog(chat_history=history, user_query=query)
EOF

cat > "$BASE_DIR/ev_app/urls.py" <<'EOF'
from django.urls import path
from . import views
urlpatterns = [path('', views.chat_view, name='chat')]
EOF

cat > "$BASE_DIR/ev_app/views.py" <<'EOF'
from django.shortcuts import render
from django.http import HttpResponse
def chat_view(request):
    return HttpResponse("<h1>EV Rental Agent Active</h1><p>Chat interface placeholder.</p>")
EOF

# 4. Data Loader
touch "$BASE_DIR/ev_app/management/__init__.py"
touch "$BASE_DIR/ev_app/management/commands/__init__.py"
cat > "$BASE_DIR/ev_app/management/commands/load_inventory.py" <<'EOF'
import csv
import os
from django.core.management.base import BaseCommand
from ev_app.models import EVCar
class Command(BaseCommand):
    help = 'Load EV inventory from CSV'
    def handle(self, *args, **options):
        file_path = '/app/data/cars.csv'
        if not os.path.exists(file_path): return
        with open(file_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                EVCar.objects.update_or_create(model_name=row['model_name'], defaults={'range_km': int(row['range_km']), 'price_per_day': float(row['price_per_day']), 'status': row['status']})
        self.stdout.write(self.style.SUCCESS(f'Successfully loaded inventory.'))
EOF

cat > "$BASE_DIR/data/cars.csv" <<EOF
model_name,range_km,price_per_day,status
Tesla Model 3,450,2500,AVAILABLE
BYD Atto 3,420,1800,AVAILABLE
ORA Good Cat,400,1500,AVAILABLE
EOF

# Generate Tutorial
cat > "$BASE_DIR/README.md" <<'EOF'
# 🥘 Chapter 2: Orchestration Basics

**Goal:** Deploy the **EV Rental Agent**, a "Modular Monolith" consisting of a Django Web App and a PostgreSQL Database.

## 🚀 Skill 2.1: Stack Deployment
**Task:** Use Docker Compose to act as the "Recipe Card."

1. **Configure Secrets:**
   Open `.env` and add your `GEMINI_API_KEY`.
2. **Build and Run:**
   ```bash
   docker-compose up --build -d
   ```
3. **Verify:**
   - Web: `http://localhost:8000`
   - Logs: `docker-compose logs -f web`

## 🦭 Skill 2.2: Platform Migration (Podman)
**Task:** Switch from the Docker Daemon to Daemonless Podman.

1. Stop Docker:
   ```bash
   docker-compose down
   ```
2. Enable Alias (if installed):
   ```bash
   alias docker=podman
   ```
3. Run again:
   ```bash
   docker-compose up -d
   ```

## 🔒 Skill 2.3: Rootless Security
**Task:** Verify the app is running as a non-privileged user.

1. Inspect the running container:
   ```bash
   docker exec ev_agent_web id
   ```
   *Expected Output:* `uid=1000(appuser) gid=1000(appuser)` (Not root!)
EOF

echo "✅ Chapter 2 Setup Complete."
echo "👉 Go to $BASE_DIR and run 'docker-compose up --build'"