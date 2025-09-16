roduct.category else {},
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