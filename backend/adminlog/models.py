from django.db import models
# adminlog/models.py
from django.db import models
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.utils.translation import gettext_lazy as _
from api.models import CustomUser

class LogEntry(models.Model):
    action_time = models.DateTimeField(_('action time'), auto_now_add=True)
    user = models.ForeignKey(
        CustomUser,
        on_delete=models.CASCADE,
        verbose_name=_('user'),
        related_name='adminlog_entries',  # ← ここを追加！
    )
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='adminlog_entries',  # ← ここも追加！
    )
    object_id = models.TextField(_('object id'), blank=True, null=True)
    object_repr = models.CharField(_('object repr'), max_length=200)
    action_flag = models.PositiveSmallIntegerField(_('action flag'))
    change_message = models.TextField(_('change message'), blank=True)

    content_object = GenericForeignKey()

    class Meta:
        verbose_name = _('log entry')
        verbose_name_plural = _('log entries')
        ordering = ['-action_time']
