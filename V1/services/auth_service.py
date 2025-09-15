from django.contrib.auth import authenticate
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from rest_framework import status
from django.contrib.auth.hashers import check_password
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.conf import settings
from django.urls import reverse
from rest_framework_simplejwt.authentication import JWTAuthentication
from allauth.socialaccount.providers.google.views import GoogleOAuth2Adapter
from allauth.socialaccount.providers.oauth2.client import OAuth2Client
from dj_rest_auth.registration.views import SocialLoginView
from dj_rest_auth.serializers import JWTSerializer

User = get_user_model()


class GoogleLoginView(SocialLoginView):
    adapter_class = GoogleOAuth2Adapter
    client_class = OAuth2Client
    callback_url = 'moderntr://auth/callback'

    # def post(self, request, *args, **kwargs):
    #     # Extract email from Google token before proceeding
    #     email = request.data.get("email")

    #     if not email:
    #         return Response(
    #             {"error": "Email not provided from Google."},
    #             status=status.HTTP_400_BAD_REQUEST
    #         )

    #     if not User.objects.filter(email=email).exists():
    #         return Response(
    #             {"error": "No account found for this Google email. Please register first."},
    #             status=status.HTTP_404_NOT_FOUND
    #         )

    #     return super().post(request, *args, **kwargs)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email")
        password = request.data.get("password")
        
        if not email or not password:
            return Response({"error": "Email and password are required"}, status=status.HTTP_400_BAD_REQUEST)

        user = authenticate(username=email, password=password)
        
        if user is not None:
            if user.is_active:
                refresh = RefreshToken.for_user(user)
                return Response({
                    "access_token": str(refresh.access_token),
                    "refresh_token": str(refresh),
                    "message": "Login successful"
                })
            else:
                return Response({"error": "Account not active. Please verify your email."}, 
                             status=status.HTTP_401_UNAUTHORIZED)
        else:
            return Response({"error": "Invalid credentials"}, 
                          status=status.HTTP_401_UNAUTHORIZED)


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email")
        password = request.data.get("password")
        first_name = request.data.get("first_name", "")
        last_name = request.data.get("last_name", "")
        
        if not email or not password:
            return Response({"error": "Email and password are required"}, 
                          status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(email=email).exists():
            return Response({"error": "Email already exists"}, 
                          status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.create_user(
                username=email,
                email=email,
                password=password,
                first_name=first_name,
                last_name=last_name,
                is_active=False  # Email verification required
            )

            # Generate verification token and link
            token = default_token_generator.make_token(user)
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            verification_link = request.build_absolute_uri(
                reverse('accounts:verify-email',kwargs={'uidb64':uid,'token':token})
            )

            # Send verification email
            subject = "Verify Your Email"
            message = f"""
            Hi {first_name},

            Thank you for signing up. Please verify your email by clicking the link below:

            {verification_link}

            Best regards,
           Modern Trade market Team
            """
            
            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )

            return Response({
                "message": "Registration successful. Please check your email to verify your account."
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({"error": str(e)}, 
                          status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class VerifyEmailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, uidb64, token):
        try:
            uid = force_str(urlsafe_base64_decode(uidb64))
            user = User.objects.get(pk=uid)
            
            if default_token_generator.check_token(user, token):
                user.is_active = True
                user.save()
                
                # Automatically log the user in after verification
                refresh = RefreshToken.for_user(user)
                return Response({
                    "access_token": str(refresh.access_token),
                    "refresh_token": str(refresh),
                    "message": "Email verified successfully"
                })
            else:
                return Response({"error": "Invalid verification link"}, 
                              status=status.HTTP_400_BAD_REQUEST)
                
        except (TypeError, ValueError, OverflowError, User.DoesNotExist) as e:
            return Response({"error": "Invalid verification link"}, 
                          status=status.HTTP_400_BAD_REQUEST)


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email")
        
        if not email:
            return Response({"error": "Email is required"}, 
                          status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
            
            # Generate password reset token and link
            token = default_token_generator.make_token(user)
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            # reset_link = f"{settings.SITE_URL}/reset-password/{uid}/{token}/"
            reset_link = request.build_absolute_uri(
                    reverse('accounts:change-password', kwargs={'uidb64': uid, 'token': token})
                )

            # Send reset email
            subject = "Password Reset Request"
            message = f"""
            Hi {user.first_name},

            You requested a password reset. Please click the link below to reset your password:

            {reset_link}

            If you didn't request this, please ignore this email.

            Best regards,
            Modern Trade Team
            """
            
            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )

            return Response({
                "message": "Password reset link sent to your email"
            })

        except User.DoesNotExist:
            return Response({"error": "No user with that email exists"}, 
                          status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            print(e)
            return Response({"error": str(e)}, 
                          status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, uidb64, token):
        try:
            uid = force_str(urlsafe_base64_decode(uidb64))
            user = User.objects.get(pk=uid)
            
            if not default_token_generator.check_token(user, token):
                return Response({"error": "Invalid reset token"}, 
                              status=status.HTTP_400_BAD_REQUEST)

            new_password = request.data.get("new_password")
            confirm_password = request.data.get("confirm_password")
            
            if not new_password or not confirm_password:
                return Response({"error": "Both password fields are required"}, 
                              status=status.HTTP_400_BAD_REQUEST)
                
            if new_password != confirm_password:
                return Response({"error": "Passwords do not match"}, 
                              status=status.HTTP_400_BAD_REQUEST)
                
            user.set_password(new_password)
            user.save()
            
            return Response({"message": "Password reset successfully"})
            
        except (TypeError, ValueError, OverflowError, User.DoesNotExist) as e:
            return Response({"error": "Invalid reset link"}, 
                          status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def post(self, request):
        try:
            refresh_token = request.data.get("refresh_token")
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"message": "Successfully logged out"})
        except Exception as e:
            return Response({"error": str(e)}, 
                          status=status.HTTP_400_BAD_REQUEST)


class AccountManagementView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def put(self, request):
        user = request.user
        data = request.data

        # Update basic info
        if 'first_name' in data:
            user.first_name = data['first_name']
        if 'last_name' in data:
            user.last_name = data['last_name']
        
        # Email change
        if 'email' in data:
            new_email = data['email']
            if User.objects.exclude(pk=user.pk).filter(email=new_email).exists():
                return Response({"error": "Email already in use"}, 
                              status=status.HTTP_400_BAD_REQUEST)
            user.email = new_email
            user.username = new_email
        
        # Password change
        if 'new_password' in data:
            if 'current_password' not in data:
                return Response({"error": "Current password is required"}, 
                              status=status.HTTP_400_BAD_REQUEST)
                
            if not check_password(data['current_password'], user.password):
                return Response({"error": "Current password is incorrect"}, 
                              status=status.HTTP_400_BAD_REQUEST)
                
            user.set_password(data['new_password'])
        
        user.save()
        return Response({"message": "Account updated successfully"})

class UserDetailView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        user = request.user
        data = {
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "is_active": user.is_active,
            "date_joined": user.date_joined
        }
        return Response(data)