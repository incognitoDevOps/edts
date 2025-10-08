# Complete Stripe Payment Flow - Implementation Documentation

## Overview

This document describes the complete end-to-end Stripe payment authorization flow with proper validation, user notifications, cancellation handling, and transaction management.

---

## 🔁 Payment Initialization & Validation

### When Rider Selects Stripe

**Location:** `booking_details_screen.dart` → `_handleStripeSelection()`

**Flow:**
1. User taps "Stripe" in payment method dialog
2. System validates route is calculated
3. Calculates total amount (fare + taxes)
4. Creates Stripe payment intent with manual capture
5. Presents Stripe payment sheet

**Possible Outcomes:**

#### ✅ Success - Card Authorized
```dart
- Payment intent ID stored
- Authorized amount stored
- Payment method selected
- Toast shown with hold details
```

**User Notification:**
```
"$25.50 is currently on hold. You'll only be charged the final
amount once the ride is complete. Any unused amount will be
returned to your payment method."
```
- Duration: 5 seconds
- Position: Center
- Builds trust and transparency

#### ❌ Failure - Card Declined / Insufficient Funds
```dart
- Payment method NOT selected
- Payment intent data cleared
- User shown error message
```

**User Notification:**
```
"Insufficient funds. Please check your payment method."
```

#### ❌ Failure - User Cancels Payment Sheet
```dart
- Payment method NOT selected
- Payment intent data cleared
- User shown error message
```

**User Notification:**
```
"Insufficient funds. Please check your payment method."
```

**Code Implementation:**
```dart
if (paymentResult != null) {
  // Success
  controller.stripePaymentIntentId.value = paymentIntentId;
  controller.stripePreAuthAmount.value = totalAmount;
  controller.selectedPaymentMethod.value = "Stripe";

  ShowToastDialog.showToast(
    "${amount} is currently on hold. You'll only be charged...",
    position: EasyLoadingToastPosition.center,
    duration: const Duration(seconds: 5)
  );
} else {
  // Failure or Cancel
  controller.selectedPaymentMethod.value = "";
  controller.stripePaymentIntentId.value = "";
  controller.stripePreAuthAmount.value = "";

  ShowToastDialog.showToast(
    "Insufficient funds. Please check your payment method."
  );
}
```

---

## ⚠️ Instant Booking Validation

**Location:** `booking_details_screen.dart` → `_handleInstantBooking()`

### Validation Logic

**For Wallet:**
```dart
if (walletBalance < payableAmount) {
  ShowToastDialog.showToast(
    "Insufficient funds. Please check your payment method."
  );
  return; // Block booking
}
```

**For Stripe:**
```dart
// Check 1: Payment intent exists
if (stripePaymentIntentId.isEmpty) {
  ShowToastDialog.showToast(
    "Insufficient funds. Please check your payment method."
  );
  return; // Block booking
}

// Check 2: Authorized amount sufficient
if (authorizedAmount < payableAmount) {
  ShowToastDialog.showToast(
    "Insufficient funds. Please check your payment method."
  );
  return; // Block booking
}

// All checks passed - proceed with instant booking
```

**Key Points:**
- ✅ Same validation for both booking methods
- ✅ Checks authorization exists
- ✅ Verifies amount is sufficient
- ✅ Prevents QR code generation without valid payment
- ✅ User must top up or change payment method

---

## 💳 Regular Booking Flow

**Location:** `home_controller.dart` → `bookRide()`

### Stripe Validation During Booking

```dart
if (selectedPaymentMethod == "Stripe") {
  if (stripePaymentIntentId.isEmpty) {
    ShowToastDialog.showToast(
      "Please select Stripe payment method again to authorize payment"
    );
    return false;
  }

  // Use stored payment intent
  orderModel.paymentIntentId = stripePaymentIntentId;
  orderModel.preAuthAmount = stripePreAuthAmount;
  orderModel.paymentIntentStatus = 'requires_capture';
  orderModel.preAuthCreatedAt = Timestamp.now();
}
```

**Result:**
- ✅ Hold is placed
- ✅ Ride is booked
- ✅ No new payment sheet shown
- ✅ Driver can accept

---

## ❌ Ride Cancellation After Driver Acceptance

**Location:** `payment_order_controller.dart` → `handleRideCancellation()`

### Cancellation Flow

**When Called:**
- User cancels ride after driver accepts
- Before pickup begins

**Process:**
```dart
1. Retrieves payment intent ID from order
2. Calls Stripe API to cancel payment intent
   POST /payment_intents/{id}/cancel
3. Updates order status to 'cancelled'
4. Updates ride status to cancelled
5. Saves to Firestore
6. Shows confirmation to user
```

**Stripe API Call:**
```dart
final stripeService = StripeService(
  stripeSecret: config.stripeSecret,
  publishableKey: config.publishableKey,
);

final success = await stripeService.releasePreAuthorization(
  paymentIntentId: orderModel.paymentIntentId
);
```

**Success Result:**
```dart
- Order status: 'cancelled'
- Payment intent status: 'cancelled'
- Hold released (money back to card)
- User notified
```

**User Notification:**
```
"Ride canceled. Your payment hold has been released."
```
- Duration: 4 seconds
- Position: Center

**Important Notes:**
- ⚠️ No charge is applied (unless cancellation fees configured)
- ⚠️ Hold is released immediately via Stripe API
- ⚠️ Funds return to card within 5-7 business days
- ⚠️ User sees confirmation immediately

---

## ✅ Post-Payment Handling at Ride Completion

**Location:** `payment_order_controller.dart` → `_captureStripePreAuthorization()`

### Completion Flow

**When Called:**
- Ride is completed
- User navigates to payment screen
- Clicks "Complete Payment"

**Process:**

#### Step 1: Validate Pre-Authorization
```dart
if (orderModel.paymentIntentId == null) {
  // No pre-auth, fall back to new payment
  return;
}
```

#### Step 2: Calculate Final Fare
```dart
final finalAmount = calculateAmount(); // Distance + time + taxes - coupon
```

#### Step 3: Capture from Hold
```dart
final captureResult = await stripeService.capturePreAuthorization(
  paymentIntentId: orderModel.paymentIntentId,
  finalAmount: finalAmount.toStringAsFixed(2),
);
```

**Stripe API Call:**
```
POST /payment_intents/{id}/capture
Body: {
  amount_to_capture: finalAmount * 100 (in cents)
}
```

#### Step 4: Handle Capture Result

**If Successful:**
```dart
// Update order
orderModel.paymentIntentStatus = 'captured';
orderModel.paymentStatus = true;
orderModel.status = Constant.rideComplete;

// Create transaction record
WalletTransactionModel stripeTransaction = {
  id: uuid,
  amount: finalAmount,
  paymentType: "Stripe",
  transactionId: orderId,
  userId: customerId,
  note: "Stripe payment captured - Ride ID: xxx"
};

// Save to Firestore
await FireStoreUtils.setWalletTransaction(stripeTransaction);
await FireStoreUtils.setOrder(orderModel);

// Notify user
if (finalAmount < authorizedAmount) {
  // Partial capture - some returned
  difference = authorizedAmount - finalAmount;
  ShowToastDialog.showToast(
    "Payment of $finalAmount captured successfully.
    $difference returned to your card."
  );
} else {
  // Full capture
  ShowToastDialog.showToast(
    "Payment of $finalAmount captured successfully."
  );
}
```

**If Failed:**
```dart
ShowToastDialog.showToast(
  "Payment capture failed. Please contact support."
);
```

#### Step 5: Automatic Hold Release

**Stripe automatically handles:**
- If `finalAmount < authorizedAmount` → Difference released
- If `finalAmount = authorizedAmount` → Full amount captured
- If `finalAmount > authorizedAmount` → Capture fails (can't exceed hold)

**Example:**
```
Hold placed: $30.00
Final fare: $24.50
Captured: $24.50
Released: $5.50 (automatic by Stripe)
```

---

## 🔔 User Notifications Summary

### 1. After Authorization Success
**Message:**
```
"$25.50 is currently on hold. You'll only be charged the final
amount once the ride is complete. Any unused amount will be
returned to your payment method."
```
**Duration:** 5 seconds
**Position:** Center
**Purpose:** Build trust, explain the hold

### 2. On Authorization Failure
**Message:**
```
"Insufficient funds. Please check your payment method."
```
**Duration:** Default (2-3 seconds)
**Position:** Bottom
**Purpose:** Clear error, prompt action

### 3. On Ride Cancellation
**Message:**
```
"Ride canceled. Your payment hold has been released."
```
**Duration:** 4 seconds
**Position:** Center
**Purpose:** Confirm cancellation, reassure about refund

### 4. On Payment Capture (Partial)
**Message:**
```
"Payment of $24.50 captured successfully.
$5.50 returned to your card."
```
**Duration:** 5 seconds
**Position:** Center
**Purpose:** Transparency about final charge and refund

### 5. On Payment Capture (Full)
**Message:**
```
"Payment of $30.00 captured successfully."
```
**Duration:** 4 seconds
**Position:** Center
**Purpose:** Confirm payment completed

---

## 💾 Transaction History

### Record Created At Capture

**Transaction Model:**
```dart
{
  "id": "trans-12345",
  "amount": "24.50",
  "createdDate": Timestamp.now(),
  "paymentType": "Stripe",
  "transactionId": "order-67890",
  "userId": "user-abc",
  "orderType": "city",
  "userType": "customer",
  "note": "Stripe payment captured - Ride ID: order-67890"
}
```

**Stored In:**
- Firestore `wallet_transaction` collection
- Linked to order via `transactionId`
- Visible in user's payment history
- Includes ride reference

**Accessible From:**
- User profile → Payment history
- Ride details → Transaction info
- Wallet → Transaction list

---

## 🎯 Complete User Journey

### Happy Path - Successful Ride

```
1. User enters destination
2. Clicks payment method
3. Selects "Stripe"
   → Payment sheet appears
4. Enters valid card
   → Card authorized
5. Sees: "$25.50 on hold..." message
6. Sees: "Payment Authorized ✓"
7. Clicks "Book Ride"
   → Booking succeeds
8. Driver accepts
9. Ride starts
10. Ride completes
11. Goes to payment screen
    → Sees: "Payment Pre-Authorized ✓"
12. Clicks "Complete Payment"
    → Amount captured from hold
    → No new payment sheet
13. Sees: "Payment of $23.50 captured. $2.00 returned"
14. Ride history updated
15. Transaction saved
```

### Unhappy Path 1 - Insufficient Funds

```
1. User enters destination
2. Clicks payment method
3. Selects "Stripe"
   → Payment sheet appears
4. Enters card with low balance
   → Card declined by Stripe
5. Sees: "Insufficient funds. Please check..."
6. Payment method NOT selected
7. Still on booking screen
8. Can select different method
```

### Unhappy Path 2 - Ride Cancellation

```
1-8. (Same as happy path through booking)
9. Driver accepts ride
10. User cancels before pickup
    → Cancellation triggered
11. System calls Stripe cancel API
12. Hold released
13. Sees: "Ride canceled. Hold released."
14. Order marked cancelled
15. No charge applied
```

### Unhappy Path 3 - User Cancels Authorization

```
1. User enters destination
2. Clicks payment method
3. Selects "Stripe"
   → Payment sheet appears
4. User closes sheet (clicks X or back)
5. Sees: "Insufficient funds. Please check..."
6. Payment method NOT selected
7. Can retry or use different method
```

---

## 🔒 Security & Data Flow

### Data Stored in Controller (Memory)
```dart
stripePaymentIntentId: "pi_abc123"
stripePreAuthAmount: "25.50"
```
- ✅ Temporary storage
- ✅ Cleared after booking
- ✅ Not persisted to disk

### Data Stored in Firestore (Database)
```dart
Order Document: {
  paymentIntentId: "pi_abc123",
  preAuthAmount: "25.50",
  paymentIntentStatus: "requires_capture",
  preAuthCreatedAt: Timestamp,
  paymentStatus: false,
  status: "placed"
}
```
- ✅ Permanent record
- ✅ Synced across devices
- ✅ Audit trail

### Status Transitions

**Order Status:**
```
placed → accepted → started → completed
   ↓
cancelled (if cancelled)
```

**Payment Intent Status:**
```
requires_capture → captured (on success)
      ↓
   cancelled (if ride cancelled)
```

**Payment Status:**
```
false → true (when captured)
```

---

## 🧪 Testing Scenarios

### Test 1: Successful Authorization
- Card: `4242 4242 4242 4242`
- Expected: Hold placed, notification shown

### Test 2: Insufficient Funds
- Card: `4000 0000 0000 9995`
- Expected: "Insufficient funds" message

### Test 3: User Cancel
- Action: Close payment sheet
- Expected: "Insufficient funds" message

### Test 4: Successful Capture
- Complete ride with authorized payment
- Expected: Capture notification with amount

### Test 5: Partial Capture
- Hold: $30, Final: $25
- Expected: "captured... $5 returned" message

### Test 6: Cancellation
- Cancel after booking
- Expected: "Hold released" message

---

## 📊 Monitoring & Debugging

### Console Logs
```
🔄 - Processing
✅ - Success
❌ - Error
💳 - Stripe specific
💰 - Payment amounts
💾 - Data saved
```

### Key Log Messages
```
"✅ Pre-authorization captured successfully"
"💾 Transaction history saved for payment: xxx"
"✅ Pre-authorization released successfully"
"❌ Failed to capture pre-authorization"
```

### Stripe Dashboard Verification
1. Login to dashboard.stripe.com
2. Go to Payments
3. Search by payment intent ID
4. Verify status transitions:
   - `requires_capture` after booking
   - `succeeded` after capture
   - `canceled` after cancellation

---

## ✅ Implementation Checklist

- [x] Authorization on payment selection
- [x] Hold notification with full message
- [x] Insufficient funds validation
- [x] Cancel handling with clear message
- [x] Instant booking validation
- [x] No double payment (pre-authorized check)
- [x] Payment capture at completion
- [x] Partial capture handling
- [x] Transaction history storage
- [x] Order status updates
- [x] User notifications for all states
- [x] Cancellation with hold release
- [x] Proper error handling
- [x] Console logging
- [x] Complete documentation

---

## Status: ✅ Complete

All requirements implemented with proper notifications, validation, and user communication.
