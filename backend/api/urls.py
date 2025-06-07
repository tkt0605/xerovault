from django.urls import path, include
from django.conf.urls.static import static
from django.conf import settings

urlpatterns = [

]
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root = settings.STATIC_ROOT)
