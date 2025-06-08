from django.db import models
from django.contrib.auth import get_user_model
from django.conf import settings
import uuid
User = get_user_model()
class CustomOutstandingToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    jti = models.UUIDField(default=uuid.uuid4)
    token = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.token} - {self.jti}"
