from django.shortcuts import render
from rest_framework import viewsets, permissions
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from .models import GeneratePublicToken, CustomUser, GenerateGroup
from rest_framework.views import APIView
from rest_framework.generics import CreateAPIView
from .serializers import RegisterSerializer, CustomUserSerializer, CustomUserDetairsSerializer, EmailLoginSerializer, LoginSerializer, LogoutSerializer, GeneratePublicTokenSerializer, GenerateGroupSerializer, GenerateGroupReadSerializer, GeneratePublicTokenReadSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta
from django.contrib.auth import get_user_model
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
            return[AllowAny()]
        return super().get_permissions()
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return GenerateGroupReadSerializer
        return super().get_serializer_class()
    def perform_create(self, serializer):
        serializer.save(founder=self.request.user)
    @action(detail=False, methods=['post'], permission_classes = [IsAuthenticated])
    def create_group(self, request):
        serializer = GenerateGroupSerializer(data=request.data)
        if serializer.is_valid():
            group = serializer.save(founder=self.request.user)
            return Response('グループが作成されました。', status=201)
        return Response(serializer.errors, status=400)
    @action(detail=False, methods=['get'], permission_classes = [IsAuthenticated])
    def my_groups(self, request):
        user = self.request.user
        groups = GenerateGroup.objects.filter(founder=user)
        serializer = GenerateGroupReadSerializer(groups, many=True)
        return Response(serializer.data)
