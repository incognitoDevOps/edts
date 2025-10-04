# Stripe Payment Authorization Hold Implementation

This document describes the Stripe payment authorization hold flow implemented in the BuzRyde rideshare application.

## Overview

The app now implements a pre-authorization hold system similar to Uber, where:
1. A temporary hold is placed on the rider's card when booking
2. The actual fare is captured after ride completion
3. Any unused amount is automatically released
4. Holds are released if the ride is cancelled

## Implementation Components

### 1. StripeService (`lib/services/stripe_service.dart`)

A dedicated service class that handles all Stripe API interactions:

**Key Methods:**
- `createPreAuthorization()` - Creates a payment intent with manual capture
- `capturePreAuthorization()` - Captures the final amount after ride completion
- `releasePreAuthorization()` - Cancels the hold if ride is cancelled
- `initPaymentSheet()` - Initializes the Stripe payment sheet
- `presentPaymentSheet()` - Presents the payment UI to the user

### 2. OrderModel Updates (`lib/model/order_model.dart`)

Added fields to track authorization status:
- `paymentIntentId` - Stripe payment intent ID
- `preAuthAmount` - Amount initially authorized
- `paymentIntentStatus` - Status: 'requires_capture', 'captured', 'cancelled'
- `preAuthCreatedAt` - Timestamp of authorization creation

### 3. HomeController Updates (`lib/controller/home_controller.dart`)

**Booking Flow (lines 509-595):**

When a user selects Stripe as payment method and books a ride:

1. **Pre-Authorization Creation:**
   - Calculates total amount including taxes
   - Creates Stripe payment intent with `capture_method: 'manual'`
   - Initializes and presents the Stripe payment sheet
   - User completes payment authorization

2. **Balance Verification:**
   - If card has insufficient funds, shows "Insufficient balance" toast
   - Checks for declined cards or balance issues
   - Provides clear error messaging to user

3. **Order Creation:**
   - Stores `paymentIntentId` in the order
   - Sets `preAuthAmount` and `paymentIntentStatus`
   - Creates the ride request in Firestore

### 4. PaymentOrderController Updates (`lib/controller/payment_order_controller.dart`)

**Ride Completion Flow:**

When ride is completed and payment needs to be finalized:

1. **Pre-Authorization Capture (lines 533-577):**
   - Retrieves the stored payment intent ID
   - Calculates final fare amount (may differ from initial estimate)
   - Captures the exact amount needed from the hold
   - Updates payment status to 'captured'

2. **Standard Payment Processing:**
   - Creates wallet transactions
   - Updates driver wallet
   - Processes admin commission
   - Sends notifications

**Ride Cancellation Flow (lines 267-318):**

When ride is cancelled:

1. **Authorization Release:**
   - Retrieves the payment intent ID
   - Calls Stripe API to cancel the hold
   - Funds are released back to the card (usually within 5-7 days)
   - Updates payment status to 'cancelled'
   - Shows confirmation toast to user

2. **Wallet Refund:**
   - If wallet was used, immediately refunds the amount
   - Creates refund transaction record

## User Experience Flow

### Successful Ride Flow

```
1. User selects destination and Stripe payment
   ↓
2. System calculates estimated fare + taxes
   ↓
3. Stripe payment sheet appears
   ↓
4. User authorizes payment with card
   ↓
5. If insufficient balance → Show "Insufficient balance" toast
   If successful → Payment hold placed
   ↓
6. Ride proceeds
   ↓
7. Ride completes
   ↓
8. System captures final amount from hold
   ↓
9. Difference automatically released by card network
```

### Cancellation Flow

```
1. User cancels ride
   ↓
2. System calls handleRideCancellation()
   ↓
3. Stripe pre-authorization cancelled via API
   ↓
4. Hold released (funds available in 5-7 days)
   ↓
5. User sees "Payment authorization released" toast
```

## Key Features

### 1. Insufficient Balance Detection
- Checks card balance before ride starts
- Shows clear "Insufficient balance" message
- Prevents failed rides due to payment issues

### 2. Dynamic Amount Capture
- Initial authorization based on estimated fare
- Final capture based on actual fare
- Handles cases where final fare differs from estimate

### 3. Automatic Refund Handling
- Hold automatically released on cancellation
- No manual intervention needed
- Clear user feedback on cancellation

### 4. Error Handling
- Comprehensive error checking at each step
- User-friendly error messages
- Fallback mechanisms for API failures

## Technical Details

### Stripe API Integration

**Base URL:** `https://api.stripe.com/v1/`

**Endpoints Used:**
- `POST /payment_intents` - Create pre-authorization
- `POST /payment_intents/:id/capture` - Capture amount
- `POST /payment_intents/:id/cancel` - Release hold

**Authentication:**
- Uses Bearer token with Stripe secret key
- Key retrieved from PaymentModel configuration

### Amount Handling

All amounts are:
- Stored as decimal strings (e.g., "25.50")
- Converted to cents for Stripe (multiply by 100)
- Rounded to avoid decimal issues
- Include tax calculations

### Status Tracking

**Payment Intent Statuses:**
- `requires_capture` - Hold placed, awaiting capture
- `captured` - Payment successfully captured
- `cancelled` - Hold released/cancelled

## Security Considerations

1. **API Keys:**
   - Secret key never exposed to client
   - Stored securely in PaymentModel
   - Retrieved from Firestore settings

2. **Amount Validation:**
   - All amounts validated before API calls
   - Minimum/maximum limits enforced
   - Tax calculations verified

3. **Error Logging:**
   - Comprehensive logging for debugging
   - No sensitive data in logs
   - Clear audit trail

## Testing Checklist

- [ ] Test with sufficient card balance
- [ ] Test with insufficient card balance → verify "Insufficient balance" message
- [ ] Test ride completion → verify amount captured correctly
- [ ] Test ride cancellation → verify hold released
- [ ] Test with amount increase (final > estimate)
- [ ] Test with amount decrease (final < estimate)
- [ ] Test network failures during authorization
- [ ] Test network failures during capture
- [ ] Verify wallet integration still works
- [ ] Verify cash payment still works

## Configuration

Ensure Stripe is properly configured:

1. Navigate to Firebase Console
2. Update `payment_gateway` collection
3. Set Stripe credentials:
   - `clientpublishableKey`
   - `stripeSecret`
   - `enable: true`

## Support Notes

Common issues and solutions:

**"Stripe is not configured properly"**
- Check Firebase payment_gateway settings
- Verify both publishable key and secret key are set

**"Insufficient balance"**
- User's card doesn't have enough funds
- User should try different payment method
- Amount includes taxes and fees

**"Payment authorization failed"**
- Network issue or Stripe API error
- User should retry
- Check Stripe dashboard for details

**"Failed to capture payment"**
- Contact support immediately
- Check Stripe dashboard
- May need manual capture via dashboard

## Future Enhancements

Potential improvements:
1. Save card details for faster checkout
2. Support for multiple cards
3. Automatic retry on capture failure
4. Real-time hold adjustment during ride
5. Detailed payment history in app
6. Support for Stripe Connect for driver payouts
