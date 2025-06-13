from django.db import models
from django.contrib.auth.models import AbstractUser, AbstractBaseUser, AnonymousUser, BaseUserManager, Permission, PermissionsMixin, Group
from django.utils import timezone
from django.conf import settings
import uuid
from config.settings import AUTH_USER_MODEL
from django.utils.translation import gettext_lazy as _
from django.utils.encoding import force_str

def generate_uuid():
    return str(uuid.uuid4())
def generate_avatar_path(instance, filename):
    ext=filename.split('.')[-1]
    filename=f'avatar.{ext}'
    return f'avatars/{instance.id}/{filename}'
class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('メールアドレスは必須です。')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save()
        return user
    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff',True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)
class CustomUser(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=generate_uuid, editable=False)
    # avater = models.ImageField(
    #     upload_to=generate_avatar_path,
    #     default = 'avaters/default_avatar.png',
    #     blank=True,
    #     null=True,
    # )
    avater = models.URLField(blank=True, null=True)
    email = models.EmailField(unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    objects = CustomUserManager()
    groups = models.ManyToManyField(
        Group,
        related_name='customuser_set',
        blank=True,
        help_text='ユーザーが所属するグループ'
    )
    user_permissions = models.ManyToManyField(
        Permission,
        related_name='customuser_set',
        blank=True,
        help_text='ユーザーに付与された権限'
    )
    date_joined = models.DateTimeField(default=timezone.now, editable=False)
    USERNAME_FIELD='email'
    REQUIRED_FIELDS = []
    def __str__(self):
        return self.email
class GeneratePublicToken(models.Model):
    user = models.ForeignKey(AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='tokens')
    groups = models.ForeignKey(AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='group_tokens', default='')
    token = models.UUIDField(default=uuid.uuid4)
    is_used = models.BooleanField(default=False)
    is_valid = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return self.token
    def save(self, *args, **kwargs):
        if not self.pk and GeneratePublicToken.objects.filter(user=self.user).count() >= 10:
            raise ValueError('ユーザーの公開トークンは最大10個までです。')
        super().save(*args, **kwargs)
    class Meta:
        unique_together = ('user', 'groups')
        verbose_name = 'Generate Token'
        verbose_name_plural = 'Generate Tokens'

class GenerateGroup(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, unique=True)
    owner = models.ForeignKey(AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='owned_group', default='')
    members = models.ManyToManyField(AUTH_USER_MODEL, related_name='joined_name', blank=True)
    description = models.TextField(blank=True)
    joined_token = models.UUIDField(default=uuid.uuid4)
    is_public = models.BooleanField(default=False)
    requires_secret_key = models.BooleanField(default=True)
    crated_at = models.DateTimeField(auto_created=True, auto_now_add=True)
    token_expiry = models.DateTimeField(null=True, blank=True)
    def __str__(self):
        return self.name
    class Meta:
        verbose_name = 'Generate Group'
        verbose_name_plural = 'Generate Groups'
