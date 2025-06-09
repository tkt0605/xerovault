from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from .models import GeneratePublicToken, CustomUser, GenerateGroup
from rest_framework_simplejwt.tokens import RefreshToken
User = get_user_model()
class RegisterSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'password1', 'password2']
        extra_kwargs = {
            'email': {'required': True, 'allow_blank': False},
            'password1': {'required': True, 'allow_blank': False},
            'password2': {'required': True, 'allow_blank': False},
        }

    def validate(self, attrs):
        if attrs['password1'] != attrs['password2']:
            raise serializers.ValidationError(_("パスワードが一致しません。"))
        return attrs

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password1'],
        )
        return user
class EmailLoginSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True, allow_blank=False)
    password = serializers.CharField(write_only=True, required=True, allow_blank=False)

    def validate(self, data):
        user = User.objects.filter(email=data['email']).first()
        if user and user.check_password(data['password']):
            return user
        raise serializers.ValidationError(_('メールアドレスまたはパスワードが正しくありません。'))

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True, allow_blank=False)
    password = serializers.CharField(write_only=True, required=True, allow_blank=False)

    def validate(self, data):
        user = User.objects.filter(email=data['email']).first()
        if user and user.check_password(data['password']):
            return user
        raise serializers.ValidationError(_('メールアドレスまたはパスワードが正しくありません。'))

class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()
    def validate(self, data):
        self.token = data['refresh']
        return data
    def save(self, **kwargs):
        RefreshToken(self.token).blacklist()
# class AuthUserSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = User
#         fields = ['id', 'email', 'avater']

class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'avater', 'is_active', 'is_staff', 'is_superuser']
        read_only_fields = ['id', 'email', 'avater', 'date_joined']

class CustomUserDetairsSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'avater', 'is_active', 'is_staff', 'is_superuser',]
        read_only_fields = ['id', 'is_active', 'is_staff', 'is_superuser', 'date_joined']


class GeneratePublicTokenSerializer(serializers.ModelSerializer):
    user = serializers.SlugRelatedField(
        slug_field='email',
        queryset=CustomUser.objects.all(),
        required=False,
        allow_null=True,
    )
    class Meta:
        model = GeneratePublicToken
        fields = ['id', 'user', 'token', 'created_at', 'expires_at']
        read_only_fields = ['id', 'user', 'created_at', 'expires_at']
class GeneratePublicTokenReadSerializer(serializers.ModelSerializer):
    user = CustomUserSerializer(read_only=True)
    class Meta:
        model = GeneratePublicToken
        fields = ['id', 'user', 'token', 'created_at', 'expires_at']



class GenerateGroupSerializer(serializers.ModelSerializer):
    founder = serializers.SlugRelatedField(
        slug_field='email',
        queryset=CustomUser.objects.all(),
        required=False,
        allow_null=True
    )
    class Meta:
        model = GenerateGroup
        fields = ['id', 'name', 'founder', 'crated_at', 'updated_at']
        read_only_fields = ['id', 'founder', 'crated_at', 'updated_at']
class GenerateGroupReadSerializer(serializers.ModelSerializer):
    founder = CustomUserSerializer(read_only=True)
    class Meta:
        model = GenerateGroup
        fields = ['id', 'name', 'founder', 'crated_at', 'updated_at']
        read_only_fields = ['id', 'founder', 'crated_at', 'updated_at']

