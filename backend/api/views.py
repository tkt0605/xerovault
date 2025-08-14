from django.shortcuts import render
from rest_framework import viewsets, permissions
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from .models import  CustomUser, GenerateGroup, GenerateLibrary, Goal, ConnectLibrary, GroupNotification, Message, PostfileToLibrary, GoalVote
from rest_framework.views import APIView
from rest_framework.generics import CreateAPIView
from .serializers import GoalVoteSerializer, PostLibraryCreateSerializer, GoalVoteReadSerializer, RegisterSerializer,MessageSerializer,MessageReadSerializer , CustomUserSerializer, CustomUserDetairsSerializer, EmailLoginSerializer, LogoutSerializer, GenerateGroupSerializer, GenerateGroupReadSerializer, GenerateLibrarySerializer, GenerateLibraryReadSerializer, GoalSerializer, GoalReadSerializer, ConnectLibrarySerializer, ConnectLibraryReadSerializer, PostLibraryReadSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta
from django.contrib.auth import get_user_model
from django.db.models import Q
from rest_framework import status
from .utils.crypto import encrypt_invite, decrypt_invite
from django.shortcuts import get_object_or_404
import uuid,time
from django.http import FileResponse, Http404
from urllib.parse import quote, unquote
from django.utils.encoding import smart_str
import mimetypes, os
from rest_framework.request import Request
from typing import cast
from .utils.utils import pretty_filename
from django.db import transaction
from django.db.models import Count, Q, F, FloatField, Value
from django.db.models.functions import NullIf, Coalesce
User = get_user_model()
class EmailLoginAPI(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = EmailLoginSerializer(data=request.data, context={'request': request})
        if serializer.is_valid(raise_exception=True):
            user = cast(CustomUser, serializer.validated_data['user'])
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

# class GeneratePublicTokenViewSet(viewsets.ModelViewSet):
#     queryset = GeneratePublicToken.objects.all()
#     serializer_class = GeneratePublicTokenSerializer
#     permission_classes = [IsAuthenticated]
#     def get_permissions(self):
#         if self.action in ['create', 'list']:
#             return [AllowAny()]
#         return super().get_permissions()
#     def get_serializer_class(self):
#         if self.action == 'retrieve':
#             return GeneratePublicTokenReadSerializer
#         return super().get_serializer_class()
#     @action(detail=False, methods=['post'], permission_classes = [IsAuthenticated])
#     def generate_token(self, request):
#         serializer = GeneratePublicTokenSerializer(data=request.data)
#         if serializer.is_valid():
#             token = serializer.save()
#             return Response({'token': token.token}, status=201)
#         return Response(serializer.errors, status=400)
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
            return [IsAuthenticated()]
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
        request = cast(Request, self.request)
        qs = (
            Goal.objects.select_related("group", "assignee")
            .annotate(
                member_count = Count("group__members", distinct=True),
                yes_counter = Count("votes", filter = Q(votes__is_yes=True), distinct=True),
            )
            .annotate(
                progress_anno = Coalesce(
                    100.0 * F("yes_counter") / NullIf(F("member_count"), 0),
                    Value(0.0),
                    output_field=FloatField()
                )
            ).order_by("-created_at")
        )
        group_id = request.query_params.get("group")
        if group_id:
            qs = qs.filter(group_id = group_id)
        return qs

    @action(detail=True, methods=['post', 'patch', 'delete'], permission_classes=[IsAuthenticated])
    def vote(self, request, pk=None):
        goal: Goal = self.get_object()
        user = request.user

        # 権限チェック：オーナー or メンバー
        if not (goal.group.members.filter(id=user.id).exists() or goal.group.owner_id == user.id):
            return Response({'detail': 'このユーザーはグループのメンバー又は、オーナーではありません。'},
                            status=status.HTTP_403_FORBIDDEN)

        # --- DELETE: 投票削除 ---
        if request.method == 'DELETE':
            with transaction.atomic():
                deleted, _ = GoalVote.objects.filter(goal=goal, voter=user).delete()
                # 達成解除の仕様：必要なら check で解除/維持を決める
                completed = goal.check_voting_completion()
                progress = goal.vote_progress()
            if deleted:
                # 204だと body 返せない → 200で状態を返す方がUI更新しやすい
                return Response({'ok': True, 'deleted': True, 'progress': progress, 'completed': completed},
                                status=status.HTTP_200_OK)
            return Response({"detail": "投票が見つかりません。"}, status=status.HTTP_404_NOT_FOUND)

        # --- POST/PATCH: 投票作成 or 更新 ---
        raw = request.data.get('is_yes')
        if raw is None:
            return Response({'detail': 'is_yes は必須です。'}, status=status.HTTP_400_BAD_REQUEST)

        if isinstance(raw, str):
            is_yes = raw.lower() in ('true', '1', 'yes', 'y', 't')
        else:
            is_yes = bool(raw)

        with transaction.atomic():
            vote, created = GoalVote.objects.update_or_create(
                goal=goal,
                voter=user,
                defaults={
                    'is_yes': is_yes,
                    # 任意：GoalVote に group フィールドがある場合、集計を楽にするため冪等に埋める
                    # 'group': goal.group,
                }
            )
            completed = goal.check_voting_completion()
            progress = goal.vote_progress()

        return Response(
            {
                'ok': True,
                'created': created,
                'vote': {'is_yes': vote.is_yes},
                'progress': progress,       # 0〜100 の整数
                'completed': completed,     # bool (今回の操作で達成したか)
            },
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )
    # @action(detail=True, methods=['post', 'patch', 'delete'], permission_classes=[IsAuthenticated])
    # def vote(self, request, pk=None):
    #     goal = self.get_object()
    #     user = request.user
    #     is_member = goal.group.members.filter(id=user.id).exists()
    #     is_owner = (goal.group.owner_id == user.id)
    #     if not (is_member or is_owner):
    #         return Response({'detail': 'このユーザーはグループのメンバー又は、オーナーではありません。'}, status=status.HTTP_403_FORBIDDEN)
    #     if request.method.lower() == 'delete':
    #         deleted, _ = GoalVote.objects.filter(goal=goal, voter=user).delete()
    #         if deleted:
    #             goal.check_voting_completion()
    #             return Response(status=status.HTTP_204_NO_CONTENT)
    #         return Response({"detail": "投票が見つかりません。"}, status=status.HTTP_404_NOT_FOUND)
    #     raw = request.data.get('is_yes')
    #     if isinstance(raw, str):
    #         is_yes = raw.lower() in ('true', '1', 'yes', 'y', 't')
    #     else:
    #         is_yes = bool(raw)
    #     vote, created = GoalVote.objects.update_or_create(
    #         goal=goal, voter=user, defaults={'is_yes': is_yes}
    #     )
    #     goal.check_voting_completion()
    #     return Response({'vote': {'is_yes': vote.is_yes}},
    #                     status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
    #                     )
class ConnectLibraryViewSet(viewsets.ModelViewSet):
    queryset = ConnectLibrary.objects.all()
    serializer_class = ConnectLibrarySerializer
    permission_classes = [IsAuthenticated]
    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return ConnectLibraryReadSerializer
        return ConnectLibrarySerializer
    @action(detail=False, methods=['post'], url_path='create_connection', url_name='create_connection')
    def create_connection(self, request, *args, **kwargs):
        user = request.user
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
    def get_queryset(self):
        qs = super().get_queryset()
        group_id = self.request.query_params.get('group')
        if group_id in (None, '', 'null', 'undefined'):
            return qs
        try:
            group_uuid = uuid.UUID(group_id)
        except (ValueError, AttributeError, TypeError):
            raise ValueError("Invalid group ID format.")
        return qs.filter(group__id=group_uuid)



# class InviteAppoverViewSet(viewsets.ModelViewSet):
#     queryset = InviteAppover.objects.all()
#     permission_classes = [IsAuthenticated]
#     serializer_class = InviteAppoverSerializer
#     def get_serializer_class(self):
#         if self.action == 'retrieve':
#             return InviteApproverReadSerializer
#         return super().get_serializer_class()
#     def perform_create(self, serializer):
#         serializer.save(inviter=self.request.user)
#     @action(detail=True, methods=['post'], url_path='approver')
#     def approver_invite(self, request, *args, **kwargs):
#         invite = self.get_object()
#         if invite.expires_at:
#             return Response({'error': 'この招待リンクは期限切れです。'}, status=400)
#         if invite.is_approved:
#             return Response({'error': 'このリンクは既に利用されています。'}, status=400)
#         invite.invitee = request.user
#         invite.is_approved = True
#         invite.save()
#         return Response(self.get_serializer(invite).data, status=200)
#     @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
#     def my_friends(self, request):
#         user = self.request.user
#         my_list = InviteAppover.objects.filter(
#             Q(inviter=user)
#         )
#         serializer = InviteApproverReadSerializer(my_list, many=True)
#         return Response(serializer.data)

class MessageViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = MessageSerializer
    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return MessageReadSerializer
        return MessageSerializer 
    # def get_queryset(self):
    #     request = cast(Request, self.request)
    #     queryset = Message.objects.all()
    #     group_id = request.query_params.get('group')
    #     if group_id:
    #         return self.queryset.filter(group=group_id)
    #     return queryset
    def get_queryset(self):
        request = cast(Request, self.request)
        user = self.request.user
        queryset = Message.objects.filter(
            Q(group__owner=user) | Q(group__members=user)
        ).order_by('-created_at')
        goal_id = request.query_params.get('goal')
        if goal_id:
            queryset = queryset.filter(goal=goal_id)
        return queryset
    def perform_create(self, serializer):
        serializer.save(auther=self.request.user)
class GetFilesView(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        # create のみ「複数ファイル」用 serializer
        if self.action == 'create':
            return PostLibraryCreateSerializer
        # list / retrieve / update などは読む用
        return PostLibraryReadSerializer

    def get_queryset(self):
        request = cast(Request, self.request)
        queryset = PostfileToLibrary.objects.all()
        lib_id = request.query_params.get('target')
        if lib_id:
            return queryset.filter(target__id=lib_id)
        return queryset

    def create(self, request, *args, **kwargs):
        """
        フロントは FormData で:
          target: <id>
          name: <str>
          files: <file> (同じキー名で複数 append)
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # 権限チェック（必要なら追加）
        # target = serializer.validated_data['target']
        # if target.owner != request.user: return Response(..., 403)

        objs = serializer.save(auther=request.user)  # ← list が返る
        read_ser = PostLibraryReadSerializer(objs, many=True)
        return Response(read_ser.data, status=status.HTTP_201_CREATED)
    def _check_object_permission(self, request, obj):
        user = request.user
        # ここをあなたの権限設計に合わせて実装
        # 所有者 or グループメンバー など
        # if not (obj.owner == user or obj.group.members.filter(id=user.id).exists()):
        #     raise PermissionDenied("アクセス権がありません。")
        return True
    @action(detail=True, methods=['get'], url_path='download', permission_classes=[IsAuthenticated])
    def download(self, request, pk=None):
        obj = self.get_object()  # get_object() は見つからないと自動で 404 を投げます
        # ストレージ上の実体
        f = obj.file
        try:
            fileobj = f.open('rb')  # S3 等のリモートでもOK
        except FileNotFoundError:
            raise Http404("File not found")

        # 表示用ファイル名（URLエンコード解除 → ベース名抽出）
        raw_name = pretty_filename(getattr(f, 'name', 'file'))
        display_name = unquote(raw_name) if '%' in raw_name else raw_name

        # Content-Type（拡張子から推測）
        content_type = mimetypes.guess_type(display_name)[0] or 'application/octet-stream'

        # inline / attachment 切替
        as_attachment = request.query_params.get('download') == '1'

        # ★ Django に任せる（filename で Unicode 指定可。Django が filename* も付ける）
        resp = FileResponse(
            fileobj,
            as_attachment=as_attachment,
            filename=display_name,
            content_type=content_type,
        )
        return resp
        # try:
        #     obj = self.get_object()
        # except PostfileToLibrary.DoesNotExist:
        #     raise Http404
        # f = obj.file  # FileField
        # # 保存名を日本語で（例: DB/Storage上のfile.name から）
        # raw_name = os.path.basename(f.name)
        # display_name = unquote(raw_name)  # 念のためURLエンコードを解除
        # content_type = mimetypes.guess_type(display_name)[0] or 'application/octet-stream'

        # resp = FileResponse(f.open('rb'), content_type=content_type)

        # # inline か attachment を切り替え（任意）
        # disp = 'inline'
        # if request.query_params.get('download') == '1':
        #     disp = 'attachment'

        # # ASCII用に安全化した代替名（空白やカンマなども避けるのが吉）
        # ascii_fallback = quote(display_name)  # ここは本来ASCIIのみが望ましい

        # # 両対応: filename (ASCII) + filename* (UTF-8)
        # resp['Content-Disposition'] = (
        #     f'{disp}; name="{ascii_fallback}"; '
        #     f"name*=UTF-8''{quote(display_name)}"
        # )
        # return resp
class GoalVoteViewSet(viewsets.ModelViewSet):
    serializer_class = GoalVoteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        request = cast(Request, self.request)
        user = self.request.user
        qs = GoalVote.objects.select_related('goal', 'voter', 'goal__group')
        qs = qs.filter(
            Q(goal__group__members = user) | Q(goal__group__owner = user)
        )
        group_id = request.query_params.get('group')
        if group_id:
            qs = qs.filter(goal__group=group_id)
        return qs.order_by('-created_at')
        # queryset = GoalVote.objects.all()
        # group_id = self.request.query_params.get('group')
        # if group_id:
        #     return queryset.filter(group=group_id)
        # return queryset
    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return GoalVoteReadSerializer
        return GoalVoteSerializer
    def perform_create(self, serializer):
        user = self.request.user
        return serializer.save(voter=user)