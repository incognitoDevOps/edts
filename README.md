I have provided:

The Flutter essential libraries including:

service, constants, screens, widgets, helper, and others.

The Django backend V1 API files to reference or edit for backend-related tasks.

Based on this, please help me implement or fix the following requirements:

✅ Frontend (Flutter) Requirements

Load More in Home Screen (Pagination-like)

Initially display the first 20 products.

Implement "load more on scroll" functionality to load additional products dynamically once the user reaches the scroll limit.

Load More in Products Under Category

Apply the same “load more on scroll” logic as above to the category-specific product listing pages.

Increase Image Upload Limit

Update the image size limit to 3MB (currently 2MB) for the following:

Create Store

Create Product

Update Profile

Back Button Navigation Fix

Ensure back button:

Returns to the immediate previous screen.

On the final screen (e.g. Home), prompt the user with a toast: "Are you sure you want to exit?"

Ads Page Redirect Fix (After 'Pay Later')

Currently, clicking "Pay Later" redirects to the create ad page.

Instead, it should redirect to the ads page, just like it does after a successful payment.

Add Option to Edit/Delete Ads

Implement the ability to edit or delete ads directly from the ads page.

🛠️ Backend (Django) & API Issues

Incorrect Store Creation Date

The created_at field appears to return a hardcoded or dummy value.

Fix this to return the actual date/time the store was created.

Product Update Not Working

Editing/updating products via the API is currently broken.

Diagnose and fix the issue.

User Product Listing Incomplete

When listing products associated with a user, some personal data is missing.

Ensure all relevant fields are included in the API response.

Payment Confirmation Fails on Frontend

After M-Pesa confirms the deduction, the system incorrectly displays a “payment failed” screen on the Flutter app.

Backend confirms payment, but frontend isn't updated — fix the flow to reflect payment success accurately.