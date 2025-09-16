# scripts/create_superuser.py
import os
import django
from django.contrib.auth import get_user_model

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

User = get_user_model()
email = "takatokomada17@gmail.com"
password = "20050605"

if not User.objects.filter(email=email).exists():
    print("🛠️ Creating superuser...")
    User.objects.create_superuser(email=email, password=password)
    print("✅ Superuser created.")
else:
    print("✅ Superuser already exists.")
