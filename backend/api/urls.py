from django.urls import path, include
from django.conf.urls.static import static
from django.conf import settings
from rest_framework import routers
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView, TokenBlacklistView
from api import views
from api.views import RegisterAPI, EmailLoginAPI, LogoutAPI, CustomUserViewSet, GenerateGroupviewSet, GeneratePublicTokenViewSet
router = routers.DefaultRouter()
router.register(r'users', CustomUserViewSet, basename='user')
router.register(r'groups', GenerateGroupviewSet, basename='group')
router.register(r'tokens', GeneratePublicTokenViewSet, basename='token')

urlpatterns = [
    path('token/', TokenObtainPairView.as_view(), name='token-login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('token/logout/', TokenBlacklistView.as_view(), name='token-logout'),
    path('logout/', LogoutAPI.as_view(), name='logout'),
    path('login/', EmailLoginAPI.as_view(), name='login'),
    path('signup/', RegisterAPI.as_view(), name='signup'),
    path('', include(routers.urls))
]
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root = settings.STATIC_ROOT)
