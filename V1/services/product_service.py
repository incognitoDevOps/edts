from inventory.models import *
from django.conf import settings
import os
import uuid
from django.utils.text import slugify
from django.core.files.storage import default_storage
from django.core.exceptions import ValidationError
from inventory.models import Product, ProductImage, Category, SubCategory, Variant, UnitOfMeasurement, County, SubCounty
from vendors.models import Store
from rest_framework.response import Response
from rest_framework import status
from django.core.paginator import Paginator
import html
from django.db.models import Sum, Q, Count, Prefetch
from django.utils import timezone
from django.db import models
from django.core.cache import cache
from django.db import transaction

class ProductService:
    
    @staticmethod
    def get_categories_with_subcategories_and_variants(request):
        """Optimized category fetching with caching"""
        cache_key = 'categories_with_subcategories_variants'
        cached_data = cache.get(cache_key)
        
        if cached_data:
            return cached_data
            
        # Use prefetch_related with specific fields to reduce query complexity
        categories = Category.objects.prefetch_related(
            Prefetch('subcategories', 
                    queryset=SubCategory.objects.only('id', 'name', 'category_id')
                    .prefetch_related(
                        Prefetch('variants', 
                                queryset=Variant.objects.only('id', 'name', 'subcategory_id'))
                    ))
        ).only('id', 'name', 'slug', 'created_date', 'background').all()
        
        domain = request.build_absolute_uri('/')[:-1]
        data = []

        for category in categories:
            subcategories = []
            for subcategory in category.subcategories.all():
                subcategories.append({
                    'id': subcategory.id,
                    'name': subcategory.name,
                    'variants': list(subcategory.variants.values('id', 'name'))
                })

            background_url = f"{domain}{category.background.url}" if category.background else None

            data.append({
                'id': category.id,
                'name': category.name,
                'slug': category.slug,
                'created_date': category.created_date,
                'background': background_url,
                'total_products': category.products.count(),  # More efficient
                'total_views': category.tot_views(),
                'subcategories': subcategories,
            })

        # Cache for 1 hour
        cache.set(cache_key, data, timeout=3600)
        return data

    @staticmethod
    def get_units_of_measurement():
        """Cached units of measurement"""
        cache_key = 'units_of_measurement'
        cached_data = cache.get(cache_key)
        
        if cached_data:
            return cached_data
            
        data = list(UnitOfMeasurement.objects.values('id', 'name', 'abbreviation'))
        cache.set(cache_key, data, timeout=86400)  # 24 hours
        return data
    
    @staticmethod
    def create_store(data, user):
        """
        Creates a new store for a user.

        :param data: Dictionary containing store details.
        :param user: The authenticated user creating the store.
        :return: Response object with store data or error message.
        """
        try:
            # Extracting all required fields
            name = data.get('name')
            address = data.get('address')
            phone_number = data.get('phone_number')
            email = data.get('email')
            description = data.get('description', '')
            product = data.get('product', '')
            logo = data.get('logo', None)  # Expecting a file upload

            facebook = data.get('facebook', None)
            twitter = data.get('twitter', None)
            linkedin = data.get('linkedin', None)
            plus = data.get('plus', None)

            # Validate required fields
            if not all([name, address, phone_number, email, product, description]):
                return Response({"error": "Missing required fields."}, status=status.HTTP_400_BAD_REQUEST)

            # Ensure user does not already own a store
            if Store.objects.filter(owner=user).exists():
                return Response({"error": "User already owns a store."}, status=status.HTTP_400_BAD_REQUEST)

            # Generate unique slug
            
            while Store.objects.filter(name=name).exists():
                                
                                return Response({"error": "Store with that name already exists."}, status=status.HTTP_400_BAD_REQUEST)

            # Create store instance
            store = Store.objects.create(
                name=name,
                address=address,
                phone_number=phone_number,
                email=email,
                description=description,
                product=product,
                owner=user,
                logo=logo,
                facebook=facebook,
                twitter=twitter,
                linkedin=linkedin,
                plus=plus
            )

            return Response({
                "message": "Store created successfully!",
                "store": {
                    "id": store.id,
                    "name": store.name,
                    "address": store.address,
                    "phone_number": store.phone_number,
                    "email": store.email,
                    "description": store.description,
                    "product": store.product,
                    "logo": store.logo.url if store.logo else None,
                    "social_links": {
                        "facebook": store.facebook,
                        "twitter": store.twitter,
                        "linkedin": store.linkedin,
                        "plus": store.plus,
                    }
                }
            }, status=status.HTTP_201_CREATED)

        except ValidationError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(e)
            return Response({"error": f"Unexpected error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @staticmethod
    def get_counties_with_subcounties():
        """Cached counties with subcounties"""
        cache_key = 'counties_with_subcounties'
        cached_data = cache.get(cache_key)
        
        if cached_data:
            return cached_data
            
        counties = County.objects.prefetch_related(
            Prefetch('subcounties', queryset=SubCounty.objects.only('id', 'name', 'county_id'))
        ).only('id', 'name').all()
        
        data = []
        for county in counties:
            data.append({
                'id': county.id,
                'name': county.name,
                'subcounties': list(county.subcounties.values('id', 'name'))
            })
            
        cache.set(cache_key, data, timeout=86400)  # 24 hours
        return data

    @staticmethod
    @transaction.atomic
    def create_product(data, images, store_id):
        """
        Creates a new product with transaction safety and optimized queries.
        """
        try:
            # Extract data with validation
            name = data.get('name')
            description = data.get('description', '')
            category_id = data.get('category')
            sub_category_id = data.get('sub_category')
            price = data.get('price')
            variant_ids = data.get('variant_ids', [])
            unit_of_measurement_id = data.get('unit_of_measurement')
            county_id = data.get('county')
            subcounty_id = data.get('subcounty')
            town = data.get('town', '')

            # Validate required fields
            if not all([name, category_id, price, store_id]):
                raise ValidationError("Name, category, price, and store are required fields.")

            # Use select_for_update for related objects to prevent race conditions
            category = Category.objects.select_for_update().get(id=category_id)
            store = Store.objects.select_for_update().get(id=store_id)
            
            # Get other related objects if provided
            sub_category = SubCategory.objects.get(id=sub_category_id) if sub_category_id else None
            unit_of_measurement = UnitOfMeasurement.objects.get(id=unit_of_measurement_id) if unit_of_measurement_id else None
            county = County.objects.get(id=county_id) if county_id else None
            subcounty = SubCounty.objects.get(id=subcounty_id) if subcounty_id else None

            # Generate unique slug
            base_slug = slugify(name)
            slug = base_slug
            counter = 1
            while Product.objects.filter(slug=slug).exists():
                slug = f"{base_slug}-{counter}"
                counter += 1

            # Create product
            product = Product.objects.create(
                name=name,
                slug=slug,
                description=description,
                category=category,
                sub_category=sub_category,
                price=price,
                store=store,
                unit_of_measurement=unit_of_measurement,
                county=county,
                subcounty=subcounty,
                town=town,
                image=images[0] if images else None
            )

            # Associate variants if provided
            if variant_ids:
                variants = Variant.objects.filter(id__in=variant_ids)
                product.variants.set(variants)  # Use many-to-many if available, otherwise adjust

            # Save images in bulk
            if images:
                product_images = [ProductImage(product=product, image=image) for image in images]
                ProductImage.objects.bulk_create(product_images)

            # Invalidate relevant caches
            cache.delete('categories_with_subcategories_variants')
            
            return product

        except (Category.DoesNotExist, Store.DoesNotExist, Variant.DoesNotExist, 
                UnitOfMeasurement.DoesNotExist, County.DoesNotExist, SubCounty.DoesNotExist):
            raise ValidationError("Invalid ID provided.")
        except Exception as e:
            raise ValidationError(str(e))

    @staticmethod
    def fetch_products(page_no, per_page, request):
        """
        Optimized product fetching with reduced database queries.
        """
        # Get filter parameters
        filters = Q(deactivated=False)
        
        county_id = request.query_params.get('county')
        subcounty_id = request.query_params.get('subcounty')
        category_id = request.query_params.get('category')
        subcategory_id = request.query_params.get('subcategory')
        variant_id = request.query_params.get('variant')
        search_query = request.query_params.get('q')

        # Apply filters
        if county_id:
            filters &= Q(county_id=county_id)
        if subcounty_id:
            filters &= Q(subcounty_id=subcounty_id)
        if category_id:
            filters &= Q(category_id=category_id)
        if subcategory_id:
            filters &= Q(sub_category_id=subcategory_id)
        if variant_id:
            filters &= Q(variant_id=variant_id)
        if search_query:
            filters &= (Q(name__icontains=search_query) | Q(description__icontains=search_query))

        # Optimized query with select_related and prefetch_related
        products = Product.objects.select_related(
            'category', 'sub_category', 'variant', 'county', 'subcounty', 'store'
        ).prefetch_related(
            Prefetch('images', queryset=ProductImage.objects.only('image', 'product_id'))
        ).filter(filters).order_by('-created_at')

        # Pagination
        paginator = Paginator(products, per_page)
        page = paginator.get_page(page_no)

        domain = request.build_absolute_uri('/')[:-1]

        # Prefetch all images for the page to avoid N+1 queries
        product_ids = [product.id for product in page.object_list]
        images_by_product = {}
        
        if product_ids:
            product_images = ProductImage.objects.filter(product_id__in=product_ids)
            for img in product_images:
                if img.product_id not in images_by_product:
                    images_by_product[img.product_id] = []
                images_by_product[img.product_id].append(f"{domain}{img.image.url}")

        product_list = []
        for product in page.object_list:
            images = images_by_product.get(product.id, [])
            
            product_list.append({
                'id': product.id,
                'name': product.name,
                'slug': product.slug,
                'description': product.description[:300] + '...' if len(product.description) > 300 else product.description,
                'price': float(product.price),
                'store': product.store.name if product.store else None,
                'category': product.category.name,
                'sub_category': product.sub_category.name if product.sub_category else None,
                'image': images[0] if images else None,
                'images': images,
                'county': product.county.name if product.county else None,
                'subcounty': product.subcounty.name if product.subcounty else None,
                'town': product.town,
                'created_at': product.created_at.isoformat(),
                'updated_at': product.updated_at.isoformat(),
            })

        return {
            "items": product_list,
            "total": paginator.count,
            "page": page.number,
            "per_page": per_page,
            "has_next": page.has_next(),
            "has_previous": page.has_previous(),
        }

    @staticmethod
    def top_viewed(request):
        """
        Optimized top viewed products with proper annotation.
        """
        # Use annotation to get view counts efficiently
        products = Product.objects.select_related(
            'category', 'sub_category', 'variant', 'county', 'subcounty', 'store'
        ).prefetch_related(
            Prefetch('images', queryset=ProductImage.objects.only('image', 'product_id'))
        ).filter(deactivated=False).annotate(
            view_count=Count('views')
        ).order_by('-view_count')[:20]

        domain = request.build_absolute_uri('/')[:-1]
        
        # Prefetch images
        product_ids = [product.id for product in products]
        images_by_product = {}
        
        if product_ids:
            product_images = ProductImage.objects.filter(product_id__in=product_ids)
            for img in product_images:
                if img.product_id not in images_by_product:
                    images_by_product[img.product_id] = []
                images_by_product[img.product_id].append(f"{domain}{img.image.url}")

        product_list = []
        for product in products:
            images = images_by_product.get(product.id, [])
            
            product_list.append({
                'id': product.id,
                'name': product.name,
                'slug': product.slug,
                'description': product.description[:200] + '...' if len(product.description) > 200 else product.description,
                'price': float(product.price),
                'store': product.store.name if product.store else None,
                'category': product.category.name,
                'sub_category': product.sub_category.name if product.sub_category else None,
                'image': images[0] if images else None,
                'images': images,
                'county': product.county.name if product.county else None,
                'subcounty': product.subcounty.name if product.subcounty else None,
                'town': product.town,
                'created_at': product.created_at.isoformat(),
                'updated_at': product.updated_at.isoformat(),
                'view_count': product.view_count,
            })

        return {
            "items": product_list,
            "total": len(product_list),
        }

    @staticmethod
    def delete_product(product_id, store_id):
        """
        Deletes a product if it exists and belongs to the provided store.
        
        :param product_id: ID of the product to delete.
        :param store_id: ID of the store (or user) attempting deletion.
        :return: True if deletion is successful.
        :raises: ValidationError if the product is not found or user is not authorized.
        """
        try:
            # Ensure that the product belongs to the store that is trying to delete it.
            product = Product.objects.get(id=product_id, store_id=store_id)
            product.delete()
            return True
        except Product.DoesNotExist:
            raise ValidationError("Product not found or you do not have permission to delete this product.")
        except Exception as e:
            raise ValidationError(str(e))

    @staticmethod
    def get_product(product_id, request):
        try:
            # Use select_related to optimize database queries
            product = Product.objects.select_related(
                'category', 'sub_category', 'variant', 'county', 'subcounty', 'store', 'store__owner'
            ).prefetch_related(
                Prefetch('images', queryset=ProductImage.objects.only('image', 'product_id')),
                Prefetch('reviews', queryset=Review.objects.only('name', 'rating', 'date', 'id', 'review'))
            ).get(id=product_id, deactivated=False)
            
            domain = request.build_absolute_uri('/')[:-1]
            
            # Unescape HTML entities safely
            description = html.unescape(product.description) if product.description else ""
            
            # FIX: Generate proper image URLs
            images = []
            for img in product.images.all():
                if img.image:
                    image_url = img.image.url
                    # Ensure we have a proper URL (not relative if already absolute)
                    if image_url.startswith('http'):
                        images.append(image_url)
                    else:
                        images.append(f"{domain}{image_url}")
            
            return {
                "name": product.name,
                "description": description,
                "category": {
                    "name": product.category.name,
                    "id": product.category.id
                } if product.category else {},
                "subcategory": {
                    "name": product.sub_category.name,
                    "id": product.sub_category.id,
                    "category": product.sub_category.category.name if product.sub_category and product.sub_category.category else ""
                } if product.sub_category else {},
                "variant": {
                    "name": product.variant.name,
                    "id": product.variant.id,
                    "subcategory": product.variant.subcategory.name if product.variant and product.variant.subcategory else ""
                } if product.variant else {},
                "county": product.county.name if product.county else '',
                "subcounty": product.subcounty.name if product.subcounty else '',
                "town": product.town,
                "store": {
                    "id": product.store.id,
                    "name": product.store.name,
                    "phone": product.store.phone_number,
                    "owner": {
                        "username": product.store.owner.username,
                        "id": product.store.owner.id,
                        "email": product.store.owner.email
                    } if product.store and product.store.owner else {}
                } if product.store else {},
                "price": float(product.price),
                "images": images,  # Use the properly formatted images list
                "reviews": [
                    {
                        "name": review.name,
                        "rating": review.rating,
                        "date": review.date.strftime("%d %b %Y") if review.date else "",
                        "id": review.id,
                        "review": review.review
                    } for review in product.reviews.all()
                ]
            }
        except Product.DoesNotExist:
            return None
        except Exception as e:
            # Log the error for debugging
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error in get_product: {str(e)}", exc_info=True)
            raise ValidationError(f"Could not retrieve product: {str(e)}")
    
    @staticmethod
    def list_all_products(request, boost_limit=50, most_viewed_limit=80, other_products_limit=100):
        """
        Optimized product listing with fixed image URLs.
        """
        try:
            domain = request.build_absolute_uri('/')[:-1]
            
            # Get page parameters
            page = int(request.query_params.get('page', 1))
            per_page = int(request.query_params.get('per_page', 60))
            
            base_query = Product.objects.select_related(
                'category', 'sub_category', 'variant', 'county', 'subcounty', 'store'
            ).prefetch_related(
                Prefetch('images', queryset=ProductImage.objects.only('image', 'product_id'))
            ).filter(deactivated=False)
            
            # Get boosted products
            boosted_products = base_query.filter(
                ads__status='active',
                ads__paid_status='paid',
            ).annotate(
                total_paid=Sum('ads__payments__tot_amount')
            ).distinct().order_by('-total_paid')[:boost_limit]
            
            # Get most viewed products (excluding boosted)
            boosted_ids = [p.id for p in boosted_products]
            most_viewed = base_query.exclude(
                id__in=boosted_ids
            ).annotate(
                view_count=Count('views')
            ).order_by('-view_count')[:most_viewed_limit]
            
            # Get other products (excluding boosted and most viewed)
            excluded_ids = boosted_ids + [p.id for p in most_viewed]
            other_products = base_query.exclude(
                id__in=excluded_ids
            ).order_by('-created_at')[:other_products_limit]
            
            # Combine all products
            all_products = []
            seen_ids = set()
            
            for product in boosted_products:
                if product.id not in seen_ids:
                    all_products.append(product)
                    seen_ids.add(product.id)
            
            for product in most_viewed:
                if product.id not in seen_ids:
                    all_products.append(product)
                    seen_ids.add(product.id)
            
            for product in other_products:
                if product.id not in seen_ids:
                    all_products.append(product)
                    seen_ids.add(product.id)
            
            # Prefetch images for all products with proper URL generation
            product_ids = [p.id for p in all_products]
            images_by_product = {}
            
            if product_ids:
                product_images = ProductImage.objects.filter(product_id__in=product_ids)
                for img in product_images:
                    if img.image:  # Only process if image exists
                        if img.product_id not in images_by_product:
                            images_by_product[img.product_id] = []
                        
                        image_url = img.image.url
                        # Ensure proper URL format
                        if not image_url.startswith('http'):
                            image_url = f"{domain}{image_url}"
                        
                        images_by_product[img.product_id].append(image_url)
            
            # Format products
            product_list = []
            for product in all_products:
                images = images_by_product.get(product.id, [])
                
                is_boosted = product.id in boosted_ids
                
                product_list.append({
                    'id': product.id,
                    'name': product.name,
                    'slug': product.slug,
                    'description': html.unescape(product.description[:250] + '...' 
                                            if product.description and len(product.description) > 250 
                                            else product.description or ''),
                    'price': float(product.price),
                    'store': {
                        'id': product.store.id if product.store else None,
                        'name': product.store.name if product.store else None,
                    },
                    'category': product.category.name if product.category else None,
                    'sub_category': product.sub_category.name if product.sub_category else None,
                    'variant': product.variant.name if product.variant else None,
                    'image': images[0] if images else None,
                    'images': images,
                    'county': product.county.name if product.county else None,
                    'subcounty': product.subcounty.name if product.subcounty else None,
                    'town': product.town,
                    'created_at': product.created_at.isoformat() if product.created_at else None,
                    'updated_at': product.updated_at.isoformat() if product.updated_at else None,
                    'view_count': getattr(product, 'view_count', 0),
                    'is_boosted': is_boosted,
                    'boost_amount': float(getattr(product, 'total_paid', 0)) if is_boosted else 0.0,
                })
            
            # Paginate the results
            paginator = Paginator(product_list, per_page)
            page_obj = paginator.get_page(page)
            
            return {
                "items": list(page_obj.object_list),
                "total": paginator.count,
                "page": page_obj.number,
                "per_page": per_page,
                "has_next": page_obj.has_next(),
                "has_previous": page_obj.has_previous(),
                "boosted_count": len(boosted_products),
                "most_viewed_count": len(most_viewed),
                "other_products_count": len(other_products),
            }
            
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error in list_all_products: {str(e)}", exc_info=True)
            raise ValidationError(f"Could not retrieve products: {str(e)}")
        
        
    @staticmethod
    def _format_product(product, domain):
        """Helper method to format a product consistently"""
        images = [f"{domain}{img.image.url}" if img.image else None for img in product.images.all()]
        
        # Calculate if product is boosted (has active paid ads)
        is_boosted = hasattr(product, 'total_paid') and product.total_paid is not None
        
        return {
            'id': product.id,
            'name': product.name,
            'slug': product.slug,
            'description': html.unescape(product.description),
            'price': float(product.price),
            'store': {
                'id': product.store.id,
                'name': product.store.name,
            } if product.store else None,
            'category': product.category.name,
            'sub_category': product.sub_category.name if product.sub_category else None,
            'variant': product.variant.name if product.variant else None,
            'image': images[0] if images else None,
            'images': images,
            'county': product.county.name if product.county else None,
            'subcounty': product.subcounty.name if product.subcounty else None,
            'town': product.town,
            'created_at': product.created_at,
            'updated_at': product.updated_at,
            'view_count': product.views.count(),
            'is_boosted': is_boosted,  # Now calculated based on ads
            'boost_amount': float(product.total_paid) if is_boosted else 0.0,
        }