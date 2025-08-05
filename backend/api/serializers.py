from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from .models import GeneratePublicToken, CustomUser, GenerateGroup, GenerateLibrary, Goal, ConnectLibrary, InviteAppover, Message, PostfileToLibrary, GoalVote
from rest_framework_simplejwt.tokens import RefreshToken
User = get_user_model()
class RegisterSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'password']
        extra_kwargs = {
            'email': {'required': True, 'allow_blank': False},
            'password': {'required': True, 'allow_blank': False}
        }

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
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
        fields = ['id', 'email', 'avater','approver' ]
        read_only_fields = ['id', 'email', 'avater','approver' , 'date_joined']

class CustomUserDetairsSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'avater','approver' , 'is_active', 'is_staff', 'is_superuser',]
        read_only_fields = ['id', 'is_active', 'is_staff', 'is_superuser', 'date_joined']
class GenerateGroupSerializer(serializers.ModelSerializer):
    owner = serializers.SlugRelatedField(
        slug_field='email',
        queryset=CustomUser.objects.all(),
        required=False,
        allow_null=True
    )
    members = serializers.SlugRelatedField(
        slug_field = 'email',
        queryset = CustomUser.objects.all(),
        required = False,
        allow_null = True,
        many = True
    )
    class Meta:
        model = GenerateGroup
        fields = ['id', 'name','tag' , 'owner', 'members', 'goals', 'score', 'generate_credits', 'joined_token', 'is_public', "created_at",'updated_at']
        read_only_fields = ['id', 'joined_token', 'created_at','updated_at']
class GenerateGroupReadSerializer(serializers.ModelSerializer):
    owner = CustomUserSerializer(read_only=True)
    members=CustomUserSerializer(read_only=True, many=True)
    class Meta:
        model = GenerateGroup
        fields = ['id', 'name','tag' , 'owner', 'members', 'goals', 'score', 'generate_credits', 'joined_token', 'is_public', "created_at",'updated_at']


class GeneratePublicTokenSerializer(serializers.ModelSerializer):
    user = serializers.SlugRelatedField(
        slug_field='email',
        queryset=CustomUser.objects.all(),
        required=False,
        allow_null=True,
    )
    groups = serializers.SlugRelatedField(
        slug_field = "joined_token",

        queryset=GenerateGroup.objects.all(),
        required=False,
        allow_null=True
    )
    class Meta:
        model = GeneratePublicToken
        fields = ['id', 'user', 'groups', 'token', 'is_used', 'is_valid', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
class GeneratePublicTokenReadSerializer(serializers.ModelSerializer):
    user = CustomUserSerializer(read_only=True)
    groups = GenerateGroupReadSerializer(read_only=True)
    class Meta:
        model = GeneratePublicToken
        fields = ['id', 'user', 'groups', 'token', 'is_used', 'is_valid', 'created_at', 'updated_at']

class GenerateLibrarySerializer(serializers.ModelSerializer):
    owner = serializers.SlugRelatedField(
        slug_field = 'email',
        queryset = CustomUser.objects.all(),
        required = False,
        allow_null = True
    )
    class Meta:
        model = GenerateLibrary
        fields = ['id', 'owner', 'name', 'tag', 'is_public', 'created_at', "updated_at"]
        read_only_fields = ['id','created_at', 'updated_at']

class GenerateLibraryReadSerializer(serializers.ModelSerializer):
    owner = CustomUserSerializer(read_only = True)
    class Meta:
        model = GenerateLibrary
        fields = ['id', 'owner', 'name', 'tag', 'is_public', 'created_at', "updated_at"]

class GoalSerializer(serializers.ModelSerializer):
    group = serializers.SlugRelatedField(
        slug_field = 'id',
        queryset = GenerateGroup.objects.all(),
        required = False,
        allow_null = True
    )
    assignee = serializers.SlugRelatedField(
        slug_field = 'email',
        queryset = CustomUser.objects.all(),
        required = False,
        allow_null = True
    )
    class Meta:
        model = Goal
        fields = ['id', 'group','header', 'description', "created_at", "deadline", "assignee", "is_concrete", "is_completed"]
        read_only_fields = ['id', "assignee" ,'created_at']
class GoalReadSerializer(serializers.ModelSerializer):
    group = GenerateGroupSerializer(read_only=True)
    assignee = CustomUserSerializer(read_only = True)
    class Meta:
        model = Goal
        fields = ['id', 'group','header' , 'description', "created_at", "deadline", "assignee", "is_concrete", "is_completed"]

class ConnectLibrarySerializer(serializers.ModelSerializer):
    target = serializers.SlugRelatedField(
        slug_field = "id",
        queryset = GenerateLibrary.objects.all(),
        required = False,
        allow_null = True
    )
    group = serializers.SlugRelatedField(
        slug_field = 'id',
        queryset = GenerateGroup.objects.all(),
        required = False,
        allow_null = True
    )
    class Meta:
        model = ConnectLibrary
        fields = [
            'id',
            'target',
            'group',
            'created_at'
        ]
        read_only_fields = ['id', 'created_at']
class ConnectLibraryReadSerializer(serializers.ModelSerializer):
    target = GenerateLibrarySerializer(read_only=True)
    group = GenerateGroupSerializer(read_only = True)
    class Meta:
        model = ConnectLibrary
        fields = [
            'id',
            'target',
            'group',
            'created_at'
        ]

class InviteAppoverSerializer(serializers.ModelSerializer):
    group = serializers.SlugRelatedField(
        slug_field='id',
        queryset = GenerateGroup.objects.all(),
        required = False,
        allow_null = True
    )
    inviter = serializers.SlugRelatedField(
        slug_field='email',
        queryset = CustomUser.objects.all(),
        required = False,
        allow_null = True
    )
    invitee = serializers.SlugRelatedField(
        slug_field = 'email',
        queryset = CustomUser.objects.all(),
        required = False,
        allow_null = True
    )
    class Meta:
        model = InviteAppover
        fields = ['token', 'group', 'inviter', 'invitee', 'is_approved', 'created_at', 'expires_at']
        read_only_fields = ['created_at', 'expires_at']
class InviteApproverReadSerializer(serializers.ModelSerializer):
    group = GenerateGroupSerializer(read_only=True)
    inviter = CustomUserSerializer(read_only=True)
    invitee = CustomUserSerializer(read_only=True)
    class Meta:
        model = InviteAppover
        fields = [
            'token', 'group', 'inviter', 'invitee', 'is_approved', 'created_at', 'expires_at'
        ]

class MessageSerializer(serializers.ModelSerializer):
    group = serializers.SlugRelatedField(
        slug_field ='id',
        queryset=GenerateGroup.objects.all(),
        required = False,
        allow_null = True
    )
    goal = serializers.SlugRelatedField(
        slug_field = 'id',
        queryset=Goal.objects.all(),
        required = False,
        allow_null = True
    )
    auther = serializers.SlugRelatedField(
        slug_field = 'email',
        queryset = CustomUser.objects.all(),
        required = False,
        allow_null = True
    )
    class Meta:
        model = Message
        fields = [
            'group', 'goal', 'auther', 'text', 'file', 'parent', 'created_at'
        ]
        read_only_fields = ['id', 'auther', 'created_at']

class MessageReadSerializer(serializers.ModelSerializer):
    group = GenerateGroupReadSerializer(read_only=True)
    goal = GoalReadSerializer(read_only=True)
    auther = CustomUserSerializer(read_only=True)
    class Meta:
        model = Message
        fields = [
            'id', 'group', 'goal', 'auther', 'text', 'file', 'parent', 'created_at'
        ]
class PostLibrarySerializer(serializers.ModelSerializer):
    target = serializers.SlugRelatedField(
        slug_field = 'id',
        queryset = GenerateLibrary.objects.all(),
        required = False,
        allow_null = True
    )
    auther = serializers.SlugRelatedField(
        slug_field = 'email',
        queryset = CustomUser.objects.all(),
        required = False,
        allow_null = True
    )
    class Meta:
        model = PostfileToLibrary
        fields = [
            'id','auther', 'name' , 'target', 'file', 'created_at'
        ]
        read_only_fields = [
            'id','auther', 'name' , 'target', 'file', 'created_at'
        ]
class PostLibraryReadSerializer(serializers.ModelSerializer):
    target = GenerateLibraryReadSerializer(read_only=True)
    class Meta:
        model = PostfileToLibrary
        fields = [
            'id','auther', 'name' ,'target', 'file', 'created_at'
        ]

class GoalVoteSerializer(serializers.ModelSerializer):
    group = serializers.SlugRelatedField(
        slug_field = 'id',
        queryset = GenerateGroup.objects.all(),
        required = True,
        allow_null = False
    )
    goal = serializers.SlugRelatedField(
        queryset = Goal.objects.all(),
        slug_field = 'id',
        required = True,
        allow_null = False
    )
    voter = serializers.SlugRelatedField(
        slug_field = 'email',
        read_only = True,
    )
    class Meta:
        model = GoalVote
        fields = ['group', 'goal', 'voter', 'explain', 'is_yes', 'created_at']
        read_only_fields = [ 'voter', 'created_at']
class GoalVoteReadSerializer(serializers.ModelSerializer):
    goal = GoalReadSerializer(read_only=True)
    voter = CustomUserSerializer(read_only=True)
    class Meta:
        model = GoalVote
        fields = ['group', 'goal', 'voter', 'explain' , 'is_yes', 'created_at']