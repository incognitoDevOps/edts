from django.utils import timezone
from django.db import transaction
from inventory.models import Review
from inventory.models import Product
from vendors.models import Store

class ReviewService:
    @staticmethod
    def create_review(user, product_id, rating, review_text):
        """Create a new product review."""
        try:
            product = Product.objects.get(id=product_id)

            review = Review.objects.create(
                name=user.get_full_name() or user.username,
                email=user.email,
                review=review_text,
                rating=rating,
                product=product,
                date=timezone.now()
            )

            return {"message": "Review added successfully", "review_id": review.id}, 201
        except Product.DoesNotExist:
            return {"error": "Product not found"}, 404
        except Exception as e:
            return {"error": str(e)}, 500

    @staticmethod
    def edit_review(user, review_id, rating, review_text):
        """Edit an existing product review."""
        try:
            review = Review.objects.get(id=review_id, email=user.email)

            review.rating = rating
            review.review = review_text
            review.date = timezone.now()
            review.save()

            return {"message": "Review updated successfully"}, 200
        except Review.DoesNotExist:
            return {"error": "Review not found or not owned by you"}, 404
        except Exception as e:
            return {"error": str(e)}, 500

    @staticmethod
    def delete_review(user, review_id):
        """Delete a product review."""
        try:
            review = Review.objects.get(id=review_id, email=user.email)
            review.delete()
            return {"message": "Review deleted successfully"}, 200
        except Review.DoesNotExist:
            return {"error": "Review not found or not owned by you"}, 404
        except Exception as e:
            return {"error": str(e)}, 500

    @staticmethod
    def get_store_reviews(user):
        """Retrieve all reviews for products in the current user's store."""
        try:
            store = Store.objects.get(owner=user)
            reviews = Review.objects.filter(product__store=store).select_related("product")
            return [
                {
                    "review_id": review.id,
                    "product_name": review.product.name,
                    "rating": review.rating,
                    "review": review.review,
                    "reviewer_name": review.name,
                    "date": review.date.strftime("%Y-%m-%d %H:%M"),
                }
                for review in reviews
            ]
        except Store.DoesNotExist:
            return {"error": "Store not found"}, 404

