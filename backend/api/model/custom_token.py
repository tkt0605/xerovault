from django.conf import settings
from django.db import models
import uuid
from django.contrib.auth import get_user_model

User = get_user_model()

class CustomOutStandingToken(models.Model):
    """
    JWTトークンのアウトスタンディング（未失効）状態を記録。
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        verbose_name='ユーザー',
    )
    jti = models.UUIDField(verbose_name='JTI', unique=True)
    token = models.TextField(verbose_name='トークン文字列')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='作成日時')
    expires_at = models.DateTimeField(verbose_name='有効期限')
    class Meta:
        verbose_name = 'アウトスタンディングトークン'
        verbose_name_plural = 'アウトスタンディングトークン'
        ordering = ['-created_at']
    def __str__(self):
        return f"{self.user} - {self.jti}"
class CustomBlackListToken(models.Model):
    """
    ブラックリストに登録されたトークンを記録。
    """
    token = models.ForeignKey(
        CustomOutStandingToken,
        on_delete=models.CASCADE,
        related_name='blacklisted_token'
    )
    blacklisted_at = models.DateTimeField(auto_now_add=True, verbose_name='ブラックリスト登録日時')
    class Meta:
        verbose_name = 'カスタム無効トークン'
        verbose_name_plural = 'カスタム無効トークン一覧'
        ordering = ['-blacklisted_at']
    def __str__(self):
        return f"{self.token}"
