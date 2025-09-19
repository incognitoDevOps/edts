from datetime import datetime, time
from django.db import transaction
from django.utils import timezone
from adManager.models import adManager, AdPayment
from inventory.models import Product
from vendors.models import Store
from adManager.payments import Payment

class AdService:
    @staticmethod
    def create_ad(user, product_id, start_date, end_date, cost_per_month):
        """Create and promote a product ad."""
        try:
            product = Product.objects.get(id=product_id, store__owner=user)
            store = product.store

            start_date_obj = datetime.combine(
                datetime.strptime(start_date, "%Y-%m-%d").date(), time.min
            )
            end_date_obj = datetime.combine(
                datetime.strptime(end_date, "%Y-%m-%d").date(), time.min
            )

            start_date_obj = timezone.make_aware(start_date_obj)
            end_date_obj = timezone.make_aware(end_date_obj)

            # Get today's date (without time component) for comparison
            today_date = timezone.now().date()
            start_date_date = start_date_obj.date()

            if start_date_date < today_date:
                return {"error": "Start date cannot be in the past"}, 400

            if end_date_obj <= start_date_obj:
                return {"error": "End date must be after start date"}, 400

            ad = adManager.objects.create(
                product=product,
                start_date=start_date_obj,
                end_date=end_date_obj,
                cost_per_month=cost_per_month,
                store=store,
                status="inactive",  
                paid_status="not paid"
            )

            return {"message": "Ad created successfully", "ad_id": ad.id}, 201

        except Product.DoesNotExist:
            return {"error": "Product not found or not owned by you"}, 404
        except Exception as e:
            return {"error": str(e)}, 500

    @staticmethod
    def pay_for_ad(user, ad_id, mobile_no):
        """
        Process payment for an ad via Mpesa.
        This method calls Payment.pay_ad to initiate the STK Push.
        The actual update of ad status happens when the callback is received.
        """
        try:
            ad = adManager.objects.get(id=ad_id, store__owner=user)

            if ad.paid_status == "paid":
                return {"error": "Ad is already paid for"}, 400

            total_cost = ad.tot_cost()

            # Initiate the Mpesa STK Push.
            payment_response = Payment.pay_ad(total_cost, mobile_no, ad_id)
            
            if "error" in payment_response:
                return {"error": payment_response["error"]}, 400
            else:
                
                return {
                    "message": "Payment initiated. Await confirmation.",
                    "receipt_number": payment_response.get("CheckoutRequestID", "Pending")
                }, 200
        except adManager.DoesNotExist:
            return {"error": "Ad not found or not owned by you"}, 404
        except Exception as e:
            return {"error": str(e)}, 500

    @staticmethod
    def get_user_ads(request, user):
        """Retrieve all current user's ads with basic details."""
        ads = adManager.objects.filter(store__owner=user).select_related("product")

        domain = request.build_absolute_uri('/')[:-1]

        return [
            {
                "ad_id": ad.id,
                "product_name": ad.product.name,
                "description": ad.product.description,
                "price": str(ad.product.price),
                "status": ad.status,
                "start_date": ad.start_date.strftime("%Y-%m-%d"),
                "end_date": ad.end_date.strftime("%Y-%m-%d"),
                "paid_status": ad.paid_status,
                "image": f"{ad.product.image.url}"
            }
            for ad in ads
        ]

    @staticmethod
    def get_ad_details(request, user, ad_id):
        """Retrieve a specific ad with payments and details."""
        try:
            ad = adManager.objects.get(id=ad_id, store__owner=user)
            payments = ad.payments.all()

            domain = request.build_absolute_uri('/')[:-1]

            return {
                "ad_id": ad.id,
                "product_name": ad.product.name,
                "description": ad.product.description,
                "price": str(ad.product.price),
                "status": ad.get_status_display(),
                "start_date": ad.start_date.strftime("%Y-%m-%d"),
                "end_date": ad.end_date.strftime("%Y-%m-%d"),
                "paid_status": ad.get_paid_status_display(),
                "total_spent": str(ad.tot_cost()),
                "days_run": 25,
                "paid_views": 1000,
                "image": f"{ad.product.image.url}",
                "payments": [
                    {
                        "amount": str(payment.tot_amount),
                        "mobile_no": payment.mobile_no,
                        "transaction_date": payment.transaction_date,
                        "receipt_number": payment.receipt_number,
                        "views": 2000
                    }
                    for payment in payments
                ]
            }, 200
        except adManager.DoesNotExist:
            return {"error": "Ad not found or not owned by you"}, 404

    @staticmethod
    def delete_ad(user, ad_id):
        """Delete an ad if it belongs to the user."""
        try:
            ad = adManager.objects.get(id=ad_id, store__owner=user)
            ad.delete()
            return {"message": "Ad deleted successfully"}, 200
        except adManager.DoesNotExist:
            return {"error": "Ad not found or not owned by you"}, 404
        except Exception as e:
            return {"error": str(e)}, 500

    @staticmethod
    def update_ad(user, ad_id, start_date=None, end_date=None, cost_per_month=None):
        """Update an existing ad."""
        try:
            ad = adManager.objects.get(id=ad_id, store__owner=user)
            
            if start_date:
                start_date_obj = datetime.combine(
                    datetime.strptime(start_date, "%Y-%m-%d").date(), time.min
                )
                start_date_obj = timezone.make_aware(start_date_obj)
                
                # Get today's date for comparison
                today_date = timezone.now().date()
                start_date_date = start_date_obj.date()

                if start_date_date < today_date:
                    return {"error": "Start date cannot be in the past"}, 400
                    
                ad.start_date = start_date_obj

            if end_date:
                end_date_obj = datetime.combine(
                    datetime.strptime(end_date, "%Y-%m-%d").date(), time.min
                )
                end_date_obj = timezone.make_aware(end_date_obj)
                
                if end_date_obj <= ad.start_date:
                    return {"error": "End date must be after start date"}, 400
                    
                ad.end_date = end_date_obj

            if cost_per_month:
                ad.cost_per_month = cost_per_month

            ad.save()
            return {"message": "Ad updated successfully"}, 200
            
        except adManager.DoesNotExist:
            return {"error": "Ad not found or not owned by you"}, 404
        except Exception as e:
            return {"error": str(e)}, 500