from django.urls import path
from .services.auth_service import *
from .views import *

urlpatterns = [
    path('auth/login/', LoginView.as_view(), name="login"),
    path('auth/google/', GoogleLoginView.as_view(), name='google_login'),
    path('auth/register/', RegisterView.as_view(), name="register"),
    path('auth/verify-email/<str:uidb64>/<str:token>/', VerifyEmailView.as_view(), name="verify-email"),
    path('auth/password-reset/', PasswordResetRequestView.as_view(), name="password-reset-request"),
    path('auth/password-reset/<str:uidb64>/<str:token>/', PasswordResetConfirmView.as_view(), name="password-reset-confirm"),
    path('auth/logout/', LogoutView.as_view(), name='logout'),
    path('auth/account/', AccountManagementView.as_view(), name="account-manage"),
    path('auth/account/details/', UserDetailView.as_view(), name="user-details"),

    path('products/categories/', CategoryListView.as_view(), name='get_categories'),
    path('products/units-of-measurement/', UnitOfMeasurementListView.as_view(), name='get_units_of_measurement'),
    path('products/counties/', CountyListView.as_view(), name='get_counties'),
    path("products/create/", CreateProductView.as_view(), name="create_product"),
    path("products/user/store/check/", CheckUserStoreView.as_view(), name="check_user_store"),
    path("products/create/store/", CreateStoreView.as_view(), name="check_user_store"),
    path("products/edit/store/",StoreUpdateView.as_view(),name="update-store"),
    path('products/all/', ProductListView.as_view(), name='product-list'),
    path('products/structured/',StructuredProductListView.as_view(),name='structured-product-list'), 
    path("products/fetch/",FetchProductView.as_view(),name="fetch_product"),
    path("products/store/all/",StoreProductsView.as_view(),name="fetch_product"),
    path('products/top-viewed/',TopViewedProductsView.as_view(),name='top-viewed'),
    path('products/<int:product_id>/edit/', EditProductAPIView.as_view(), name='edit-product'),
    path('products/<int:product_id>/delete/', DeleteProductAPIView.as_view(), name='delete-product'),



    path("wishlist/",WishlistView.as_view(),name='wishlist'),

    path("ads/create/", CreateAdView.as_view(), name="create-ad"),
    path("ads/pay/", PayForAdView.as_view(), name="pay-ad"),
    path("ads/", UserAdsView.as_view(), name="user-ads"),
    path("ads/<int:ad_id>/", AdDetailView.as_view(), name="ad-detail"),
    path("ads/<int:ad_id>/delete/", AdDetailView.as_view(), name="ad-delete"),
    path("ads/<int:ad_id>/update/", AdDetailView.as_view(), name="ad-update"),

    path("reviews/create/", CreateReviewView.as_view(), name="create-review"),
    path("reviews/<int:review_id>/edit/", EditReviewView.as_view(), name="edit-review"),
    path("reviews/<int:review_id>/delete/", DeleteReviewView.as_view(), name="delete-review"),
    path("reviews/store/", StoreReviewsView.as_view(), name="store-reviews"),

    path('rooms/', RoomListAPIView.as_view(), name='room-list'),
    path('rooms/<int:pk>/', RoomDetailAPIView.as_view(), name='room-detail'),
    path('rooms/<int:room_id>/messages/', MessageCreateAPIView.as_view(), name='message-create'),
    path('rooms/initiate/', InitiateRoomAPIView.as_view(), name='room-initiate'),

    path('faqs/', FAQListView.as_view(), name='faq-list'),
    path('faqs/create/', FAQCreateView.as_view(), name='faq-create'),
    path('faqs/<int:faq_id>/update/', FAQUpdateView.as_view(), name='faq-update'),
    path('faqs/<int:faq_id>/delete/', FAQDeleteView.as_view(), name='faq-delete'),

    path('stores/<int:store_id>/complaint/', FileComplaintAPIView.as_view(), name='file-complaint'),
    path('user/get-id/',CurrentUserView.as_view(),name='current-user-view')
]