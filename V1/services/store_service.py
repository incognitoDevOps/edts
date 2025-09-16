from inventory.models import Product
from vendors.models import Store
from django.core.paginator import Paginator
from rest_framework import serializers
from vendors.models import Complains

class ComplaintSerializer(serializers.ModelSerializer):
    class Meta:
        model = Complains
        fields = ['id', 'store', 'reason', 'description', 'user', 'cleared', 'created_on']
        read_only_fields = ['id', 'store', 'user', 'cleared', 'created_on']


class StoreService:
    @staticmethod
    def get_store_products(store, domain, page=1, per_page=10):
        """Fetch all products belonging to a store in a paginated manner."""
        products = Product.objects.filter(store=store).select_related(
            "category", "sub_category", "variant", "store", "county", "subcounty"
        ).prefetch_related("images")

        paginator = Paginator(products, per_page)
        product_page = paginator.get_page(page)

        # Get all images for products in this page
        product_ids = [product.id for product in product_page]
        images_by_product = {}
        
        if product_ids:
            from inventory.models import ProductImage
            product_images = ProductImage.objects.filter(product_id__in=product_ids)
            for img in product_images:
                if img.product_id not in images_by_product:
                    images_by_product[img.product_id] = []
                images_by_product[img.product_id].append(f"{img.image.url}")


        return {
            "total_products": paginator.count,
            "total_pages": paginator.num_pages,
            "current_page": product_page.number,
            "products": [
                {
                    "id": product.id,
                    "name": product.name,
                    "description": product.description,
                    "price": product.price,
                    "image": images_by_product.get(product.id, [None])[0],
                    "images": images_by_product.get(product.id, []),
                    "category": product.category.name,
                    "sub_category": product.sub_category.name if product.sub_category else None,
                    "variant": product.variant.name if product.variant else None,
                    "county": product.county.name if product.county else None,
                    "subcounty": product.subcounty.name if product.subcounty else None,
                    "town": product.town,
                    "store_id": product.store.id,
                    "store_name": product.store.name,
                    "store_phone": product.store.phone_number,
                    "store_email": product.store.email,
                    "store_address": product.store.address,
                    "owner_id": product.store.owner.id if product.store.owner else None,
                    "owner_username": product.store.owner.username if product.store.owner else None,
                    "owner_email": product.store.owner.email if product.store.owner else None,
                    "owner_first_name": product.store.owner.first_name if product.store.owner else None,
                    "owner_last_name": product.store.owner.last_name if product.store.owner else None,
                    "created_at": product.created_at.isoformat() if product.created_at else None,
                    "updated_at": product.updated_at.isoformat() if product.updated_at else None,
                }
                for product in product_page
            ]
        }
    
    @staticmethod
    def file_complaint(store, user, reason, description):
        """
        Create a complaint record for the given store.
        """
        complaint = Complains.objects.create(
            store=store,
            user=user,
            reason=reason,
            description=description
        )
        return complaint
    


    @staticmethod
    def update_store_details(store, data, logo=None):
        """Allows store owners to edit store details, including the logo."""
        fields_to_update = False

        if "name" in data:
            if Store.objects.exclude(id=store.id).filter(name=data["name"]).exists():
                return {"error": "Store name already exists"}, 400
            store.name = data["name"]
            fields_to_update = True

        if "address" in data:
            store.address = data["address"]
            fields_to_update = True

        if "phone_number" in data:
            store.phone_number = data["phone_number"]
            fields_to_update = True

        if "email" in data:
            if Store.objects.exclude(id=store.id).filter(email=data["email"]).exists():
                return {"error": "Email already in use"}, 400
            store.email = data["email"]
            fields_to_update = True

        if "description" in data:
            store.description = data["description"]
            fields_to_update = True

        if "facebook" in data:
            store.facebook = data["facebook"]
            fields_to_update = True

        if "twitter" in data:
            store.twitter = data["twitter"]
            fields_to_update = True

        if "linkedin" in data:
            store.linkedin = data["linkedin"]
            fields_to_update = True

        if "plus" in data:
            store.plus = data["plus"]
            fields_to_update = True

        if logo:
            store.logo = logo
            fields_to_update = True

        if fields_to_update:
            store.save()
            return {"message": "Store details updated successfully"}, 200
        else:
            return {"error": "No valid fields provided"}, 400
