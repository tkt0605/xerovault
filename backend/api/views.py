from django.shortcuts import render
from rest_framework import viewsets, permissions
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from .models import GeneratePublicToken, CustomUser, GenerateGroup, GenerateLibrary, Goal, ConnectLibrary, GroupNotification, InviteAppover, Message, PostfileToLibrary, GoalVote
from rest_framework.views import APIView
from rest_framework.generics import CreateAPIView
from .serializers import GoalVoteSerializer, GoalVoteReadSerializer, RegisterSerializer,MessageSerializer,MessageReadSerializer , CustomUserSerializer, CustomUserDetairsSerializer, EmailLoginSerializer, LogoutSerializer, GeneratePublicTokenSerializer, GenerateGroupSerializer, GenerateGroupReadSerializer, GeneratePublicTokenReadSerializer, GenerateLibrarySerializer, GenerateLibraryReadSerializer, GoalSerializer, GoalReadSerializer, ConnectLibrarySerializer, ConnectLibraryReadSerializer, InviteAppoverSerializer, InviteApproverReadSerializer, PostLibraryReadSerializer, PostLibrarySerializer
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta
from django.contrib.auth import get_user_model
from django.db.models import Q
from rest_framework import status
from .utils.crypto import encrypt_invite, decrypt_invite
from django.shortcuts import get_object_or_404
import uuid,time


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
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def approver_add(self, request):
        user = request.user
        approver = user.approver.all()
        serializer = self.get_serializer(approver, many=True)
        return Response(serializer.data)

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
class InviteCreateView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        group_id = request.data.get("group_id")
        expire_in = int(request.data.get('expire_in', 3600))
        group = get_object_or_404(GenerateGroup, id = group_id, owner = request.user)
        token = str(uuid.uuid4())
        exp = int(time.time()) + expire_in

        group.joined_token = token
        group.save()

        encrypted = encrypt_invite({'token': token, 'exp': exp})
        return Response({'encrypted_data': encrypted})
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

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated], url_path='join')
    def join(self, request, pk=None):
        user = self.request.user
        token = request.data.get('token')
        encrypted = request.query_params.get('data')
        if not encrypted:
            return Response({'detail': "トークンが必要です。"}, status=400)
        token = decrypt_invite(encrypted)

        if not token:
            return Response({'detail': 'トークンが必要です。'}, status=400)
        try:
            group = self.get_object()
            if group.joined_token != token['token']:
                return Response({'detail': '無効トークンです。'}, status=400)
            if token.get('exp') and int(time.time()) > token['exp']:
                return Response({'detail': 'トークンの有効期限が切れています。'}, status=400)
            # group = GenerateGroup.objects.get(join_token=token)
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
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_groups(self, request):
        user = self.request.user
        groups = GenerateGroup.objects.filter(
            Q(members=user)
        )
        serializer = GenerateGroupReadSerializer(groups, many=True)
        return Response(serializer.data)
    @action(detail=True, methods=['delete'], permission_classes=[IsAuthenticated], url_path='remove-member/(?P<user_id>[0-9a-f-]+)') 
    def remove_member(self, request, pk=None, user_id=None):
        group = self.get_object()
        if request.user != group.owner:
            return Response({'detail': 'あなたには、メンバー削除の権限がありません。'}, status=403)
        try:
            user_to_remove = CustomUser.objects.get(id=user_id)
            group.members.remove(user_to_remove)
            return Response({'detail': f'{user_to_remove.email}を削除しました。'}, status=200)
        except User.DoesNotExist:
            return Response({'detail': 'ユーザーが存在しません。'}, status=404)

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
    queryset = Goal.objects.all().order_by('-created_at')
    serializer_class = GoalSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in['create', 'list', 'my_goals']:
            return [AllowAny()]
        return super().get_permissions()
    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
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
    def get_queryset(self):
        queryset = Goal.objects.all()
        group_id = self.request.query_params.get('group')
        if group_id:
            return self.queryset.filter(group=group_id)
        return queryset
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def vote(self, request, pk=None):
        goal = self.get_object()
        user= request.user
        is_yes = request.deta.get('is_yes')
        if goal.group.members.filter(id=user.id).exists():
            vote, created = GoalVote.objects.get_or_create(
                goal=goal,
                voter=user
            )
            if not created:
                return Response({'detail': '既に投票済みです。'}, status=400)
            goal.check_voting_completion()
            return Response({'detail': '投票が記録されました'}, status=200)
        return Response({'detail': 'このグループのメンバーではありません。'}, status=403)
class ConnectLibraryViewSet(viewsets.ModelViewSet):
    queryset = ConnectLibrary.objects.all()
    serializer_class = ConnectLibrarySerializer
    permission_classes = [IsAuthenticated]
    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return ConnectLibraryReadSerializer
        return ConnectLibrarySerializer
    @action(detail=False, methods=['post'], url_path='', url_name='connect_library')
    def create_connection(self, request, *args, **kwargs):
        user = self.request.user
        print('リクエストデータ：', request.data)
        group_id = request.data.get('group')
        library_id = request.data.get('target')
        if not group_id or not library_id:
            return Response({'error': 'groupとlibraryは必須です。'}, status=400)
        try:
            group = GenerateGroup.objects.get(id=group_id)
            library = GenerateLibrary.objects.get(id=library_id)
        except (GenerateGroup.DoesNotExist, GenerateLibrary.DoesNotExist):
            return Response({'error': 'グループ又は、ライブラリが存在しません。'}, status=404)
        is_member = group.members.filter(id=user.id).exists()
        if group.owner != user and not is_member:
            return Response({'error': 'グループに参加していません。'}, status=403)
        if library.owner != user:
            return Response({"error": "あなたのライブラリではありません。"}, status=403)
        if ConnectLibrary.objects.filter(group=group, target=library).exists():
            return Response({'error': '既にドッキングしています。'}, status=404)
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return Response(serializer.data, status=201)
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated], url_path='my-library')
    def my_library(self, request):
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


class InviteAppoverViewSet(viewsets.ModelViewSet):
    queryset = InviteAppover.objects.all()
    permission_classes = [IsAuthenticated]
    serializer_class = InviteAppoverSerializer
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return InviteApproverReadSerializer
        return super().get_serializer_class()
    def perform_create(self, serializer):
        serializer.save(inviter=self.request.user)
    @action(detail=True, methods=['post'], url_path='approver')
    def approver_invite(self, request, *args, **kwargs):
        invite = self.get_object()
        if invite.expires_at:
            return Response({'error': 'この招待リンクは期限切れです。'}, status=400)
        if invite.is_approved:
            return Response({'error': 'このリンクは既に利用されています。'}, status=400)
        invite.invitee = request.user
        invite.is_approved = True
        invite.save()
        return Response(self.get_serializer(invite).data, status=200)
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_friends(self, request):
        user = self.request.user
        my_list = InviteAppover.objects.filter(
            Q(inviter=user)
        )
        serializer = InviteApproverReadSerializer(my_list, many=True)
        return Response(serializer.data)

class MessageViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = MessageSerializer
    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return MessageReadSerializer
        return MessageSerializer 
    def get_queryset(self):
        queryset = Message.objects.all()
        group_id = self.request.query_params.get('group')
        if group_id:
            return self.queryset.filter(group=group_id)
        return queryset
    def get_queryset(self):
        user = self.request.user
        queryset = Message.objects.filter(
            Q(group__owner=user) | Q(group__members=user)
        ).order_by('-created_at')
        goal_id = self.request.query_params.get('goal')
        if goal_id:
            queryset = queryset.filter(goal=goal_id)
        return queryset
    def perform_create(self, serializer):
        serializer.save(auther=self.request.user)

class UploadMultipleFilesView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        target_id = request.data.get('target')  # フロント側から送られる target ライブラリID
        files = request.FILES.getlist('file')   # name="file" の input が複数の場合

        if not target_id or not files:
            return Response({'error': 'targetとfileは必須です。'}, status=400)

        saved_files = []
        for file in files:
            serializer = PostLibrarySerializer(data={
                'target': target_id,
                'file': file
            })
            if serializer.is_valid():
                serializer.save()
                saved_files.append(serializer.data)
            else:
                return Response(serializer.errors, status=400)

        return Response({'uploaded': saved_files}, status=201)
class GetFilesView(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = PostLibrarySerializer
    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return PostLibraryReadSerializer
        return PostLibrarySerializer
    def get_queryset(self):
        user = self.request.user
        return PostfileToLibrary.objects.filter(
            Q(auther = user)
            ).order_by('-created_at')
    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(auther=user)
class GoalVoteViewSet(viewsets.ModelViewSet):
    serializer_class = GoalVoteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = GoalVote.objects.all()
        goal_id = self.request.query_params.get('goal')
        if goal_id:
            return self.queryset.filter(goal=goal_id)
        return queryset
    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return GoalVoteReadSerializer
        return GoalVoteSerializer
    def perform_create(self, serializer):
        user = self.request.user
        return serializer.save(voter=user)