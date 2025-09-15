from cart.models import Wishlist
from inventory.models import Product
from django.core.paginator import Paginator


class WishlistService:
    @staticmethod
    def get_wishlist(user, domain,page=1, per_page=10):
        """Fetch the user's wishlist with pagination."""
        wishlist_items = Wishlist.objects.filter(owner=user).select_related("product")
        
        paginator = Paginator(wishlist_items, per_page)
        wishlist_page = paginator.get_page(page)

        return {
            "total_items": paginator.count,
            "total_pages": paginator.num_pages,
            "current_page": wishlist_page.number,
            "wishlist": [
                {
                    "id": item.id,
                    "product": {
                        "id": item.product.id,
                        "name": item.product.name,
                        "price": item.product.price,
                        "description": item.product.description,
                        "image": (
                            f"{item.product.image.url}"
                            if item.product.image else None
                        ),
                        "store": item.product.store.name if item.product.store else None,
                    },
                }
                for item in wishlist_page
            ]
        }

    @staticmethod
    def add_to_wishlist(user, product_id):
        """Add a product to the user's wishlist."""
        product = Product.objects.filter(id=product_id, deactivated=False).first()

        if not product:
            return {"error": "Product not found or unavailable"}, 404

        wishlist_item, created = Wishlist.objects.get_or_create(owner=user, product=product)

        if created:
            return {"message": "Product added to wishlist"}, 201
        else:
            return {"message": "Product already in wishlist"}, 200

    @staticmethod
    def remove_from_wishlist(user, product_id):
        """Remove a product from the user's wishlist."""
        wishlist_item = Wishlist.objects.filter(owner=user,product_id=product_id).first()

        if wishlist_item:
            wishlist_item.delete()
            return {"message": "Product removed from wishlist"}, 200

        return {"error": "Product not found in wishlist"}, 404