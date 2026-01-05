#!/usr/bin/env python3
"""
Script to fix reviews/views.py to allow only sender to review driver.
Run this from trucking_desk directory: python3 fix_review_backend.py
"""

FIXED_VIEWS_CONTENT = '''from django.views.generic import View
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
import json
from .models import Review
from cargo.models import Order
from django.core.exceptions import PermissionDenied

class CreateReviewView(LoginRequiredMixin, View):
    def post(self, request):
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        order_id = data.get("order_id")
        rating = data.get("rating")
        comment = data.get("comment", "")

        if not order_id or not rating:
            return JsonResponse({"error": "Missing required fields"}, status=400)
        
        try:
            rating = int(rating)
            if not (1 <= rating <= 5):
                raise ValueError
        except ValueError:
             return JsonResponse({"error": "Rating must be an integer between 1 and 5"}, status=400)

        # Get Order
        order = get_object_or_404(Order, pk=order_id)

        # Check permission: Only sender can review
        user = request.user
        if user != order.sender:
            return JsonResponse({"error": "Only sender can leave a review"}, status=403)

        # Check status: Order must be DELIVERED or CANCELLED
        if order.status not in [Order.Status.DELIVERED, Order.Status.CANCELLED]:
             return JsonResponse({"error": "Order is not finished yet"}, status=400)

        # Check if driver exists
        if not order.driver:
             return JsonResponse({"error": "No driver to review"}, status=400)

        # Check if already reviewed
        if Review.objects.filter(order=order, reviewer=user).exists():
             return JsonResponse({"error": "You have already reviewed this order"}, status=400)

        # Create Review (sender reviews driver)
        Review.objects.create(
            order=order,
            reviewer=user,
            reviewed_user=order.driver,
            rating=rating,
            comment=comment
        )

        return JsonResponse({"message": "Review created successfully"}, status=201)
'''

if __name__ == '__main__':
    import os
    target_file = 'src/reviews/views.py'
    
    if not os.path.exists(target_file):
        print(f"Error: {target_file} not found. Make sure you're in trucking_desk directory.")
        exit(1)
    
    with open(target_file, 'w') as f:
        f.write(FIXED_VIEWS_CONTENT)
    
    print(f"✅ Updated {target_file}")
    print("⚠️  Remember to restart Django server for changes to take effect!")
