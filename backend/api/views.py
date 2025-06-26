from django.shortcuts import render
from rest_framework import viewsets, permissions
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from .models import GeneratePublicToken, CustomUser, GenerateGroup, GenerateLibrary, Goal, ConnectLibrary, GroupNotification
from rest_framework.views import APIView
from rest_framework.generics import CreateAPIView
from .serializers import RegisterSerializer, CustomUserSerializer, CustomUserDetairsSerializer, EmailLoginSerializer, LoginSerializer, LogoutSerializer, GeneratePublicTokenSerializer, GenerateGroupSerializer, GenerateGroupReadSerializer, GeneratePublicTokenReadSerializer, GenerateLibrarySerializer, GenerateLibraryReadSerializer, GoalSerializer, GoalReadSerializer, ConnectLibrarySerializer, ConnectLibraryReadSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta
from django.contrib.auth import get_user_model
from django.db.models import Q
from rest_framework import status
from .utils.crypto import encrypt_invite
User = get_user_model()
class EmailLoginAPI(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = EmailLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data
            refresh = RefreshToken.for_user(user)
            return Response({
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            })
class RegisterAPI(CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer
    queryset = CustomUser.objects.all()
class LogoutAPI(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({'message': 'ログアウトしました。'}, status=200)
        return Response(serializer.errors, status=400)
class CustomUserViewSet(viewsets.ModelViewSet):
    queryset = CustomUser.objects.all()
    serializer_class = CustomUserSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    def get_permissions(self):
        if self.action in ['create', 'list']:
            return [AllowAny()]
        return super().get_permissions()
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return CustomUserDetairsSerializer
        return super().get_serializer_class()
    @action(detail=False, methods=['get'], permission_classes = [IsAuthenticated])
    def me(self, request):
        user = request.user
        serializer = CustomUserDetairsSerializer(user)
        return Response(serializer.data)
    @action(detail=False, methods=['post'], permission_classes = [IsAuthenticated])
    def upload_avatar(self, request):
        user = request.user
        serializer = CustomUserDetairsSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=200)
        return Response(serializer.errors, status=400)
class GeneratePublicTokenViewSet(viewsets.ModelViewSet):
    queryset = GeneratePublicToken.objects.all()
    serializer_class = GeneratePublicTokenSerializer
    permission_classes = [IsAuthenticated]
    def get_permissions(self):
        if self.action in ['create', 'list']:
            return [AllowAny()]
        return super().get_permissions()
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return GeneratePublicTokenReadSerializer
        return super().get_serializer_class()
    @action(detail=False, methods=['post'], permission_classes = [IsAuthenticated])
    def generate_token(self, request):
        serializer = GeneratePublicTokenSerializer(data=request.data)
        if serializer.is_valid():
            token = serializer.save()
            return Response({'token': token.token}, status=201)
        return Response(serializer.errors, status=400)
class GenerateGroupviewSet(viewsets.ModelViewSet):
    queryset = GenerateGroup.objects.all()
    serializer_class = GenerateGroupSerializer
    permission_classes = [IsAuthenticated]
    def get_permissions(self):
        if self.action in ['create', 'list']:
            return[IsAuthenticated()]
        return super().get_permissions()
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return GenerateGroupReadSerializer
        return super().get_serializer_class()
    def create(self, request, *args, **kwargs):
        print('リクエストデータ:', request.data)  # ← 送信されたmembersの値を確認

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        group = serializer.save(owner=request.user)
        try:
            group.members.add(request.user)  # ここで例外が出る場合はリクエストに問題あり
        except Exception as e:
            print("members.add() で例外:", str(e))
            raise e  # ログが表示されるようにする

        group.refresh_from_db()
        read_serializer = self.get_serializer(group)
        return Response(read_serializer.data, status=201)
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def add_members(self, request, id=None):
        group = self.get_object()
        email = self.request.user
        if group.owner != email:
            return Response({'detail': 'あなたには、メンバーの追加権限を持ってません。'})
        if not group:
            return Response({'detail': 'groupが存在しません。'}, status=status.HTTP_404_NOT_FOUND)
        try:
            user = CustomUser.objects.get(email=email)
            target = GenerateGroup.objects.get(owner=group.owner)
            if user in target.members.all():
                return Response({'detail': "すべにメンバーです。"}, status=400)
            target.members.add(user)
            GroupNotification.objects.create(
                group=group,
                message=f"{user.email}がメンバーに追加されました。"
            )
            return Response({'detail': f'{email}を追加しました。'})
        except CustomUser.DoesNotExist:
            return Response({'detail': 'ユーザーが存在しません。'}, status=404)

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def join(self, request, pk=None):
        user = self.request.user
        # token = request.data.get('token')
        encrypted = request.query_params.get('data')
        token, error = encrypt_invite(encrypted)
        if not token:
            return Response({'detail': 'トークンが必要です。'}, status=400)
        try:
            group = GenerateGroup.objects.get(join_token=token)
        except GenerateGroup.DoesNotExist:
            return Response({'detail': '無効トークンです。'}, status=404)
        if user in group.members.all():
            return Response({'detail': 'すでに参加しています。'}, status=400)
        group.members.add(user)
        group.save()
        GroupNotification.objects.create(
            group = group,
            message = f"{user.email}がグループに参加しました。"
        )
        return Response({'detail': f"{group.name}に参加しました。"}, status=200)
    def my_groups(self, request):
        user = self.request.user
        groups = GenerateGroup.objects.filter(
            Q(owner = user) | Q(members = user)
        ).distinct()
        serializer = GenerateGroupReadSerializer(groups, many=True)
        return Response(serializer.data)


class GenerateLibraryviewSet(viewsets.ModelViewSet):
    queryset = GenerateLibrary.objects.all()
    serializer_class = GenerateLibrarySerializer
    permission_classesv= [IsAuthenticated]

    def get_permissions(self):
        if self.action in ['create', 'list']:
            return [AllowAny()]
        return super().get_permissions()
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return GenerateLibraryReadSerializer
        return super().get_serializer_class()
    def perform_create(self, serializer):
        serializer.save(owner = self.request.user)
    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def craete_library(self, request):
        serializer = GenerateLibrarySerializer(data=request.data)
        if serializer.is_valid():
            library = serializer.save(owner=self.request.user)
            return Response('ライブラリ作成されました。', status=201)
        return Response(serializer.errors, status=400)
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_library(self, request):
        user = self.request.user
        library = GenerateLibrary.objects.filter(owner=user)
        serializer = GenerateLibraryReadSerializer(library, many=True)
        return Response(serializer.data)

class GoalViewSet(viewsets.ModelViewSet):
    queryset = Goal.objects.all()
    serializer_class = GoalSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in['create', 'list']:
            return [AllowAny()]
        return super().get_permissions()
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return GoalReadSerializer
        return super().get_serializer_class()
    def perform_create(self, serializer):
        serializer.save(assignee=self.request.user)
    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def create_goals(self, request):
        serializer = GoalSerializer(data=request.data)
        if serializer.is_valid():
            goals = serializer.save(assignee=self.request.user)
            return Response('Goalが作成されました。', status=201)
        return Response(serializer.errors, status=400)
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_goals(self, request):
        user = self.request.user
        groups = GenerateGroup.objects.filter(
            Q(owner=user) |
            Q(members = user)
        )
        goals = Goal.objects.filter(group__in = groups)
        serializer = GoalReadSerializer(goals, many=True)
        return Response(serializer.data)


class ConnectLibraryViewSet(viewsets.ModelViewSet):
    queryset = ConnectLibrary.objects.all()
    serializer_class = ConnectLibrarySerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in ['create', 'list']:
            return {IsAuthenticated()}
        return super().get_permissions()
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ConnectLibraryReadSerializer
        return super().get_serializer_class()
    def create(self, request, *args, **kwargs):
        user = self.request.user
        print('リクエストデータ：', request.data)
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        group =GenerateGroup.objects.get(id = request.data['group'])
        library = GenerateLibrary.objects.get(id=request.data['target'])
        if group.owner != user and user or group.members.all():
            return Response({"error": "グループに参加していません。"}, status=403)
        if library.owner != user:
            return Response({"error": "あなたのライブラリではありません。"}, status=403)
        self.perform_create(serializer)
        return Response(serializer.data, status=201)
    def my_Connecter(self, request):
        user = self.request.user
        groups = GenerateGroup.objects.filter(
            Q(owner = user) | Q(members = user)
        )
        librarys = GenerateLibrary.objects.filter(
            owner = user
        )
        connecter = ConnectLibrary.objects.filter(
            group__in = groups, target__in = librarys
        )
        serializer = ConnectLibraryReadSerializer(connecter, many=True)
        return Response(serializer.data)
