from rest_framework.views import APIView
from rest_framework.response import Response
from inventory.models import *
from .services.product_service import ProductService
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated,AllowAny
from rest_framework.status import HTTP_201_CREATED, HTTP_400_BAD_REQUEST, HTTP_403_FORBIDDEN, HTTP_405_METHOD_NOT_ALLOWED
from django.core.exceptions import ValidationError
from inventory.models import Store
from .services.product_service import ProductService
from rest_framework import status
from .services.wishlist_service import WishlistService
from .services.store_service import StoreService,ComplaintSerializer
from .services.ad_service import AdService
from .services.review_service import ReviewService
from .services.chat_service import *
from rest_framework import generics, permissions, status
from django.shortcuts import get_object_or_404
from .services.faq_service import FAQService
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework_simplejwt.authentication import JWTAuthentication


chat_service = ChatService()


class CategoryListView(APIView):
    permission_classes = [AllowAny]
    def get(self, request):
        data = ProductService.get_categories_with_subcategories_and_variants(request)
        return Response({'categories': data})

class UnitOfMeasurementListView(APIView):
    permission_classes = [AllowAny]
    def get(self, request):
        data = ProductService.get_units_of_measurement()
        return Response({'units_of_measurement': data})

class CountyListView(APIView):
    permission_classes = [AllowAny]
    def get(self, request):
        data = ProductService.get_counties_with_subcounties()
        return Response({'counties': data})

class CreateProductView(APIView):
    """
    API endpoint to create a product. 
    Requires authentication and the user must own a store.
    """

    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def post(self, request):
        try:
            user_store = Store.objects.filter(owner=request.user).first()
            if not user_store:
                return Response({"error": "You must own a store to create a product."}, status=HTTP_403_FORBIDDEN)

            data = request.data.copy()  
            images = request.FILES.getlist("images")  

            

            product = ProductService.create_product(data, images,user_store.id)

            return Response(
                {"message": "Product created successfully", "product_id": product.id},
                status=HTTP_201_CREATED,
            )
        except ValidationError as e:
            return Response({"error": "Name, category, price, and store are required fields."}, status=HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"error": f"An unexpected error occurred: {str(e)}"}, status=HTTP_400_BAD_REQUEST)

    def get(self, request):
        return Response({"error": "Method not allowed"}, status=HTTP_405_METHOD_NOT_ALLOWED)
    
class CheckUserStoreView(APIView):
    """
    API endpoint to check if a user has a store.
    If not, the frontend should redirect to the Create Store page.
    """
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        store = Store.objects.filter(owner=request.user).first()
        if store:
            return Response({"has_store": True, "store_id": store.id})
        return Response({"has_store": False})
    

class CreateStoreView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def post(self, request):
        try:
            data = request.data.copy()  # Copy request data
            logo = request.FILES.get('logo', None)  # Handle file upload separately
            data['logo'] = logo  # Ensure the file is included in data

            response = ProductService.create_store(data, request.user)

            # If `create_store` now returns a Response object, return it directly
            return response  

        except ValidationError as e:
            return Response({"error": str(e)}, status=HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"error": f"An unexpected error occurred: {str(e)}"}, status=HTTP_400_BAD_REQUEST)

class ProductListView(APIView):
    """
    API endpoint to list products with optional pagination.
    """

    permission_classes = [AllowAny]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        page = request.query_params.get('page', 1)
        per_page = request.query_params.get('per_page', 10)

        products = ProductService.fetch_products(page, per_page,request)

        return Response({
            "products": products["items"],
            "total": products["total"],
            "page": products["page"],
            "per_page": products["per_page"],
        })

class StructuredProductListView(APIView):
    """
    API endpoint to list all products in structured format
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            # Get parameters with defaults
            params = {
                'boost_limit': int(request.query_params.get('boost_limit', 20)),
                'most_viewed_limit': int(request.query_params.get('most_viewed_limit', 20)),
                'other_products_limit': int(request.query_params.get('other_limit', 0)),
            }
            
            products_data = ProductService.list_all_products(request, **params)
            
            return Response({
                'status': 'success',
                'data': products_data,
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_200_OK)
            
        except ValidationError as e:
            return Response({
                'status': 'error',
                'message': str(e),
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            return Response({
                'status': 'error',
                'message': 'Internal server error',
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        
class EditProductAPIView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def put(self, request, product_id, format=None):
        """
        Handles full update of a product.
        """
        data = request.data.copy()
        # Extract images if provided (assuming 'images' is sent as a list of files)
        images = request.FILES.getlist('images')

        try:
            # Get store_id from the authenticated user's store
            try:
                store = Store.objects.get(owner=request.user)
                store_id = store.id
            except Store.DoesNotExist:
                return Response({"error": "You must own a store to edit products."}, status=status.HTTP_403_FORBIDDEN)
                
            product = ProductService.edit_product(product_id, data, images, store_id)
            # Optionally, serialize the product for the response.
            return Response({"message": "Product updated successfully", "product_id": product.id}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, product_id, format=None):
        """
        Handles partial update of a product.
        """
        data = request.data.copy()
        images = request.FILES.getlist('images') if 'images' in request.FILES else []
        try:
            # Get store_id from the authenticated user's store
            try:
                store = Store.objects.get(owner=request.user)
                store_id = store.id
            except Store.DoesNotExist:
                return Response({"error": "You must own a store to edit products."}, status=status.HTTP_403_FORBIDDEN)
                
            product = ProductService.edit_product(product_id, data, images, store_id)
            return Response({"message": "Product updated successfully", "product_id": product.id}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    
class FetchProductView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        product_id = request.query_params.get('product_id')

        product = ProductService.get_product(product_id, request)

        if product is None:
            return Response({"error": "Product could not be found"}, status=status.HTTP_404_NOT_FOUND)

        return Response({"product": product}, status=status.HTTP_200_OK)
    
class TopViewedProductsView(APIView):
    permission_classes = [AllowAny]  # Change if needed

    def get(self, request):
        try:
            data = ProductService.top_viewed(request)
            return Response(data, status=status.HTTP_200_OK)
        except Exception as e:
            print(e)
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    
class WishlistView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        """Fetch wishlist items."""
        page = request.query_params.get("page", 1)
        per_page = request.query_params.get("per_page", 10)

        domain = request.build_absolute_uri('/')[:-1]

        wishlist_data = WishlistService.get_wishlist(request.user,domain, page, per_page)
        return Response(wishlist_data, status=status.HTTP_200_OK)

    def post(self, request):
        """Add a product to the wishlist."""
        product_id = request.data.get("product_id")

        if not product_id:
            return Response({"error": "Product ID is required"}, status=status.HTTP_400_BAD_REQUEST)

        response, code = WishlistService.add_to_wishlist(request.user, product_id)
        return Response(response, status=code)

    def delete(self, request):
        """Remove a product from the wishlist."""
        product_id = request.query_params.get("product_id")

        if not product_id:
            return Response({"error": "Product ID is required"}, status=status.HTTP_400_BAD_REQUEST)

        response, code = WishlistService.remove_from_wishlist(request.user, product_id)
        return Response(response, status=code)

class StoreProductsView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        """Fetch all store products in a paginated manner."""
        user = request.user

        try:
            store = user.store  # Fetch the store owned by the user
        except Store.DoesNotExist:
            return Response({"error": "Store not found"}, status=status.HTTP_404_NOT_FOUND)

        page = request.query_params.get("page", 1)
        per_page = request.query_params.get("per_page", 10)

        domain = request.build_absolute_uri('/')[:-1]


        products_data = StoreService.get_store_products(store,domain, page, per_page)
        return Response(products_data, status=status.HTTP_200_OK)


class StoreUpdateView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        """Retrieve the authenticated user's store details."""
        user = request.user

        try:
            store = user.store
        except Store.DoesNotExist:
            return Response({"error": "Store not found"}, status=status.HTTP_404_NOT_FOUND)
        
        domain = request.build_absolute_uri('/')[:-1]

        store_data = {
            "name": store.name,
            "address": store.address,
            "phone_number": store.phone_number,
            "email": store.email,
            "description": store.description,
            "product": store.product,
            "logo": f"{store.logo.url}" if store.logo else None,
            "created_at": store.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "isActivated": store.isActivated,
            "flagged": store.flagged,
            "facebook": store.facebook,
            "twitter": store.twitter,
            "linkedin": store.linkedin,
            "plus": store.plus,
        }

        return Response(store_data, status=status.HTTP_200_OK)

    def put(self, request):
        """Allows store owners to update store details, including the logo."""
        user = request.user

        try:
            store = user.store
        except Store.DoesNotExist:
            return Response({"error": "Store not found"}, status=status.HTTP_404_NOT_FOUND)

        data = request.data
        logo = request.FILES.get("logo")  # Handle logo upload

        response, code = StoreService.update_store_details(store, data, logo)
        return Response(response, status=code)
    
class CreateAdView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def post(self, request):
        """Allows users to create an ad for a product."""
        data = request.data
        response, code = AdService.create_ad(
            user=request.user,
            product_id=data.get("product_id"),
            start_date=data.get("start_date"),
            end_date=data.get("end_date"),
            cost_per_month=data.get("cost_per_month"),
        )
        return Response(response, status=code)
class AdPricingConfigView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        """Returns pricing configuration for ads."""
        return Response({
            "premium_price": 150.0,
            "standard_price": 100.0,
            "premium_categories": [
                "vehicles",
                "vehicle parts", 
                "Appliances and furniture",
                "fashion",
                "electronics",
                "Phones & Tablets",
            ]
        })

class PayForAdView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def post(self, request):
        """Allows users to pay for an ad via Mpesa."""
        data = request.data

        mobile_no = data.get("mobile_no")

        mobile_no = mobile_no.lstrip('+')

        # Standardize mobile number format
        if mobile_no.startswith('0'):
            mobile_no = '254' + mobile_no[1:]

        response, code = AdService.pay_for_ad(
            user=request.user,
            ad_id=data.get("ad_id"),
            mobile_no=data.get("mobile_no"),
        )
        return Response(response, status=code)

class UserAdsView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        """Retrieves all ads created by the user."""
        ads = AdService.get_user_ads(request,user=request.user)
        return Response(ads, status=200)

class AdDetailView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request, ad_id):
        """Retrieves details of a specific ad along with payments."""
        response, code = AdService.get_ad_details(request,user=request.user, ad_id=ad_id)
        return Response(response, status=code)

    def put(self, request, ad_id):
        """Update an existing ad."""
        data = request.data
        response, code = AdService.update_ad(
            user=request.user,
            ad_id=ad_id,
            start_date=data.get("start_date"),
            end_date=data.get("end_date"),
            cost_per_month=data.get("cost_per_month"),
        )
        return Response(response, status=code)

    def delete(self, request, ad_id):
        """Delete an ad."""
        response, code = AdService.delete_ad(
            user=request.user,
            ad_id=ad_id,
        )
        return Response(response, status=code)
    
class CreateReviewView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def post(self, request):
        """Allows users to add a review to a product."""
        data = request.data
        response, code = ReviewService.create_review(
            user=request.user,
            product_id=data.get("product_id"),
            rating=data.get("rating"),
            review_text=data.get("review"),
        )
        return Response(response, status=code)

class EditReviewView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def put(self, request, review_id):
        """Allows users to edit their own review."""
        data = request.data
        response, code = ReviewService.edit_review(
            user=request.user,
            review_id=review_id,
            rating=data.get("rating"),
            review_text=data.get("review"),
        )
        return Response(response, status=code)

class DeleteReviewView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def delete(self, request, review_id):
        """Allows users to delete their own review."""
        response, code = ReviewService.delete_review(
            user=request.user,
            review_id=review_id,
        )
        return Response(response, status=code)

class StoreReviewsView(APIView):
    """Retrieve all reviews for products in the current user's store."""
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        response = ReviewService.get_store_reviews(request.user)
        # If response is a list, return 200; otherwise, use the returned status code.
        return Response(response, status=200 if isinstance(response, list) else response[1])

class RoomListAPIView(generics.ListAPIView):
    serializer_class = RoomSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Room.objects.filter(participants=user).distinct()

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.update({"request": self.request})  # ✅ Ensure request is passed for `get_unread_count`
        return context

# Retrieve messages in a room and optionally mark them as read
class RoomDetailAPIView(generics.RetrieveAPIView):
    serializer_class = RoomSerializer
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [JWTAuthentication]
    queryset = Room.objects.all()

    def retrieve(self, request, *args, **kwargs):
        room = self.get_object()
        
        # 1. Verify access
        if request.user not in room.participants.all():
            return Response({"detail": "Not authorized."}, status=status.HTTP_403_FORBIDDEN)

        # ✅ 2. Get messages (ordered newest first)
        messages = Message.objects.filter(room=room).order_by('-timestamp')

        # ✅ 3. Mark unread messages as read
        unread_statuses = MessageReadStatus.objects.filter(
            user=request.user,
            message__room=room,
            read=False
        )
        unread_statuses.update(read=True, read_at=timezone.now())

        # ✅ 4. Serialize and return
        room_serializer = RoomSerializer(room, context={'request': request})
        message_serializer = MessageSerializer(messages, many=True)

        return Response({
            "room": room_serializer.data,
            "messages": message_serializer.data
        })

# Create/send a new message in a room
class MessageCreateAPIView(generics.CreateAPIView):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def post(self, request, room_id):
        room = get_object_or_404(Room, id=room_id)
        # Ensure user is part of the room
        if request.user not in room.participants.all():
            return Response({"detail": "Not authorized."}, status=status.HTTP_403_FORBIDDEN)
        content = request.data.get("content")
        if not content:
            return Response({"detail": "Message content is required."}, status=status.HTTP_400_BAD_REQUEST)
        message = chat_service.send_message(room, request.user, content)
        serializer = MessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
class InitiateRoomAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def post(self, request):
        # Expect other_user_id to be provided in the request body
        other_user_id = request.data.get("other_user_id")
        if not other_user_id:
            return Response({"detail": "other_user_id is required."}, status=status.HTTP_400_BAD_REQUEST)
        
        # Retrieve the other user
        other_user = get_object_or_404(User, id=other_user_id)
        
        # Initiate (or get) the chat room between the current user and the other user.
        room = chat_service.initiate_chat(request.user, other_user)
        serializer = RoomSerializer(room, context={'request': request})
        return Response({"room": serializer.data}, status=status.HTTP_200_OK)
    
class FAQListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        faqs = FAQService.get_all_faqs()
        # Simple serialization of FAQ objects.
        faq_list = [{
            "id": faq.id,
            "question": faq.question,
            "answer": faq.answer,
            "created_on": faq.created_on.strftime("%Y-%m-%d")
        } for faq in faqs]
        return Response(faq_list, status=status.HTTP_200_OK)

class FAQCreateView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        question = request.data.get("question")
        answer = request.data.get("answer")
        if not question or not answer:
            return Response({"error": "Question and answer are required."},
                            status=status.HTTP_400_BAD_REQUEST)
        faq = FAQService.create_faq(question, answer)
        return Response({
            "id": faq.id,
            "question": faq.question,
            "answer": faq.answer,
            "created_on": faq.created_on.strftime("%Y-%m-%d")
        }, status=status.HTTP_201_CREATED)

class FAQUpdateView(APIView):
    permission_classes = [AllowAny]

    def put(self, request, faq_id):
        question = request.data.get("question")
        answer = request.data.get("answer")
        faq = FAQService.update_faq(faq_id, question, answer)
        if faq:
            return Response({
                "id": faq.id,
                "question": faq.question,
                "answer": faq.answer,
                "created_on": faq.created_on.strftime("%Y-%m-%d")
            }, status=status.HTTP_200_OK)
        return Response({"error": "FAQ not found."},
                        status=status.HTTP_404_NOT_FOUND)

class FAQDeleteView(APIView):
    permission_classes = [AllowAny]

    def delete(self, request, faq_id):
        success = FAQService.delete_faq(faq_id)
        if success:
            return Response({"message": "FAQ deleted successfully."},
                            status=status.HTTP_200_OK)
        return Response({"error": "FAQ not found."},
                        status=status.HTTP_404_NOT_FOUND)
    
class FileComplaintAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, store_id):
        # Retrieve the store
        store = get_object_or_404(Store, id=store_id)
        reason = request.data.get("reason")
        description = request.data.get("description")

        if not reason or not description:
            return Response(
                {"detail": "Both reason and description are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # File the complaint using the service
        complaint = StoreService.file_complaint(store, request.user, reason, description)
        serializer = ComplaintSerializer(complaint, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class DeleteProductAPIView(APIView):
    permission_classes = [IsAuthenticated]  
    authentication_classes = [JWTAuthentication]# Optional: restrict access to authenticated users

    def delete(self, request, product_id, format=None):
        # Option 1: If the store ID comes from the request's user (recommended)
        store_id = request.user.store.id  # Adjust based on your user model
        
        # Option 2: If passed via request data (less secure)
        # store_id = request.data.get("store_id")
        
        try:
            ProductService.delete_product(product_id, store_id)
            return Response({"message": "Product deleted successfully."}, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class CurrentUserView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        """
        Return the authenticated user's ID (and username, if you like).
        """
        user = request.user
        return Response({
            "id": user.id,
            "username": user.username,
        })