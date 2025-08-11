from typing import Iterable
from django.db import models
from django.contrib.auth.models import AbstractUser, AbstractBaseUser, AnonymousUser, BaseUserManager, Permission, PermissionsMixin, Group
from django.utils import timezone
from django.conf import settings
import uuid
from config.settings import AUTH_USER_MODEL
from django.utils.translation import gettext_lazy as _
from django.utils.encoding import force_str
from django.db.models.signals import post_save, post_delete, m2m_changed
from django.dispatch import receiver
from datetime import timedelta
import datetime
# --- 定数定義: スコアのルールと重み付けを定義 ---
BASE_SCORE = 100  # デフォルトのスコア
MAX_SCORE = 1000  # スコアの上限

# 加点要素の重み付け
MEMBER_WEIGHT = 15
VAGUE_GOAL_WEIGHT = 5      # 具体化されていない目標のポイント
CONCRETE_GOAL_WEIGHT = 25  # 具体化された目標のポイント
COMPLETED_GOAL_WEIGHT = 60 # 達成済み目標はさらに高ポイント

def generate_uuid():
    return str(uuid.uuid4())
def generate_avatar_path(instance, filename):
    ext=filename.split('.')[-1]
    filename=f'avatar.{ext}'
    return f'avatars/{instance.id}/{filename}'
def generate_avatar_url(email):
    """メールアドレスを基にアバター URL を生成"""
    seed = email.split("@")[0] if email else "default"
    return f"https://api.dicebear.com/7.x/identicon/svg?seed={seed}"
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
    avater = models.URLField(blank=True, null=True)
    email = models.EmailField(unique=True)
    approver = models.ManyToManyField('self', blank=True)
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
    def save(self, *args, **kwargs):
        if not self.avater:
            self.avater = generate_avatar_url(self.email)
        super().save(*args, **kwargs)
    def __str__(self):
        return self.email
def get_default_expired():
    return timezone.now() + timedelta(hours=24)
# class InviteAppover(models.Model):
#     token = models.UUIDField(default=uuid.uuid4, unique=True)
#     inviter = models.ForeignKey(AUTH_USER_MODEL, on_delete=models.CASCADE)
#     invitee = models.ForeignKey( AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='group_invite_received', null=True, blank=True)
#     is_approved = models.BooleanField(default=False)
#     created_at = models.DateTimeField(auto_now_add=True)
#     expires_at = models.DateTimeField(default=get_default_expired)
#     def __str__(self) -> str:
#         return f"{self.inviter}が{self.invitee}をリスト追加"
#     @property
#     def is_expired(self):
#         return timezone.now() > self.expires_at
#     class Meta:
#         ordering = ['-created_at']
class GenerateGroup(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, unique=True)
    owner = models.ForeignKey(AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='owned_group', default='')
    members = models.ManyToManyField(AUTH_USER_MODEL, related_name='joined_name', blank=True)
    goals = models.ManyToManyField("Goal", blank=True)
    tag = models.CharField(max_length=256, blank=True, default='')
    joined_token = models.CharField(max_length=36, unique=True, null=True, blank=True, help_text="UUID形式の招待トークン")
    is_public = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_created=True, auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    score = models.IntegerField(
        "スコア",
        default=BASE_SCORE,
        help_text=f"グループの活動状況に基づくスコア。デフォルト:{BASE_SCORE}, 最大:{MAX_SCORE}"
    )
    generate_credits = models.IntegerField('生成クレジット', default=100, help_text="生成機能を使用するためのクレジット")

    def __str__(self):
        return self.name
    def update_score(self):
        members_points = self.members.count()
        vague_goals_points = self.goals.filter(is_concrete=False, is_completed=False).count() * VAGUE_GOAL_WEIGHT
        concreate_goals_points = self.goals.filter(is_concrete=True, is_completed=False).count()*CONCRETE_GOAL_WEIGHT
        completed_goals_points = self.goals.filter(is_completed = True).count()*COMPLETED_GOAL_WEIGHT

        calculated_score = BASE_SCORE + members_points + vague_goals_points + concreate_goals_points + completed_goals_points
        new_score = min(calculated_score, MAX_SCORE)
        if self.score != new_score:
            self.score = new_score
            self.save(update_fields=['score'])
            print(f"グループ '{self.name}' のスコアが {self.score} に更新されました。")
class Goal(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    group = models.ForeignKey(GenerateGroup, on_delete=models.CASCADE, related_name='目標')
    header = models.CharField('目標タイトル', max_length=255, help_text='この目標のタイトル', default='', blank=True, null=True)
    description = models.TextField("目標内容")
    created_at = models.DateTimeField("作成日", auto_now_add=True)
    deadline = models.DateField('締め切り', null=True, blank=True, help_text='この目標の締め切り')
    assignee = models.ForeignKey(
        AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_goal',
        verbose_name='担当者',
        help_text='この目標の責任者'
    )
    is_concrete = models.BooleanField('具体化済み', default=False, help_text="締め切りか担当者が設定されると自動でTrueになります")
    is_completed = models.BooleanField('達成済み', default=False)

    def __str__(self) -> str:
        return f"{self.group.name} - {self.description[:20]}"
    def save(self, *args, **kwargs):
        if self.deadline or self.assignee:
            self.is_concrete = True
        else:
            self.is_concrete = False
        return super().save(*args, **kwargs)
    def vote_progress(self):
        total_members = self.group.members.count()
        yes_vote = self.votes.filter(is_yes=True).count()
        if total_members == 0:
            return 0
        return int(yes_vote / total_members * 100)
    def check_voting_completion(self, threshold=90):
        if self.vote_progress() >= threshold:
            self.is_completed = True
            self.save()
            return True
        return False
    

@receiver(post_save, sender=Goal)
@receiver(post_delete, sender=Goal)
def on_goal_change(sender, instance, **kwargs):
    """目標が作成・更新・削除されたら、所属グループのスコアを更新"""
    instance.group.update_score()

@receiver(m2m_changed, sender=GenerateGroup.members.through)
def on_member_change(sender, instance, action, **kwargs):
    """メンバーが追加・削除されたら、グループのスコアを更新"""
    if action in ["post_add", "post_remove"]:
        instance.update_score()


# class GeneratePublicToken(models.Model):
#     user = models.ForeignKey(AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='tokens')
#     groups = models.ForeignKey(GenerateGroup, on_delete=models.CASCADE, related_name='group_tokens', default='')
#     token = models.UUIDField(default=uuid.uuid4)
#     is_used = models.BooleanField(default=False)
#     is_valid = models.BooleanField(default=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
#     def __str__(self):
#         return self.token
#     def save(self, *args, **kwargs):
#         if not self.pk and GeneratePublicToken.objects.filter(user=self.user).count() >= 10:
#             raise ValueError('ユーザーの公開トークンは最大10個までです。')
#         super().save(*args, **kwargs)
#     class Meta:
#         unique_together = ('user', 'groups')
#         verbose_name = 'Generate Token'
#         verbose_name_plural = 'Generate Tokens'

class GenerateLibrary(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='user', default='')
    name = models.CharField(max_length=255)
    tag = models.CharField(max_length=256, blank=True, default='')
    is_public = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    def __str__(self):
        return self.name
class PostfileToLibrary(models.Model):
    target = models.ForeignKey(GenerateLibrary, on_delete=models.CASCADE, related_name='target_library', default='')
    auther = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='auther', default='')
    name = models.CharField(max_length=50, blank=True, null=True)
    file = models.FileField(upload_to='library_file')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.target    
class ConnectLibrary(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    target = models.ForeignKey(GenerateLibrary, on_delete=models.CASCADE, related_name='対象ライブラリ', default='')
    group = models.ForeignKey(GenerateGroup, on_delete=models.CASCADE, related_name="接続先スタジオ", default='')
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return self.target
    class Meta:
        unique_together = ('group', 'target')
        indexes = [
            models.Index(fields=['group', 'target']),
        ]

class GroupNotification(models.Model):
    group = models.ForeignKey(GenerateGroup, on_delete=models.CASCADE)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return super().__str__()


class Message(models.Model):
    group = models.ForeignKey(GenerateGroup, on_delete=models.CASCADE, related_name='対象グループ', blank=True, null=True)
    goal = models.ForeignKey(Goal, on_delete=models.CASCADE, related_name='対象ゴール', blank=True, null=True)
    auther = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='作者')
    text = models.TextField()
    file = models.FileField(upload_to='file/', blank=True, null=True)
    is_done = models.BooleanField(default=False, help_text='このメッセージが完了したか？')
    parent = models.ForeignKey('self', null=True, blank=True, on_delete=models.CASCADE, related_name='replies')
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return self.text

class GoalVote(models.Model):
    group = models.ForeignKey(GenerateGroup, on_delete=models.CASCADE, related_name='ターゲット', blank=True, null=True)
    goal = models.ForeignKey(Goal, on_delete=models.CASCADE, related_name='投票対象ゴール')
    explain = models.CharField(max_length=50, blank=True, null=True, help_text='この投票の目的や背景を説明するテキスト')
    voter = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='投票者')
    is_yes = models.BooleanField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['goal', 'voter'], name='uniq_goal_voter'),
        ]
        indexes = [models.Index(fields=['group', 'goal']), models.Index(fields=['voter'])]
    def __str__(self):
        return f"{self.voter.email} の {self.goal.description[:20]} への投票"