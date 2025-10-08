# Stripe Authorization Hold - Developer Quick Start

## Quick Overview

This implementation adds Uber-style payment authorization holds to your rideshare app using Stripe.

## What It Does

**Before Ride:**
- Places a temporary hold on rider's card
- Checks if sufficient balance exists
- Shows "Insufficient balance" if card is declined

**During Ride:**
- Hold remains in place
- No money captured yet

**After Ride:**
- Captures actual fare amount
- Releases any difference automatically

**If Cancelled:**
- Releases the entire hold
- Funds return to card

## Key Files

```
lib/
├── services/
│   └── stripe_service.dart          ← New: Stripe API wrapper
├── model/
│   └── order_model.dart              ← Updated: Added pre-auth fields
└── controller/
    ├── home_controller.dart          ← Updated: Booking with pre-auth
    └── payment_order_controller.dart ← Updated: Capture & cancellation
```

## Quick Test

### Test 1: Successful Booking
```dart
// 1. Select Stripe as payment
// 2. Enter valid card details
// 3. Verify authorization succeeds
// 4. Complete ride
// 5. Verify amount captured
```

### Test 2: Insufficient Balance
```dart
// Use Stripe test card: 4000000000009995 (declined)
// Expected: "Insufficient balance" toast appears
```

### Test 3: Cancellation
```dart
// 1. Book ride with Stripe
// 2. Cancel ride
// 3. Verify hold is released
// 4. Check confirmation message
```

## Stripe Test Cards

```
Success: 4242424242424242
Declined: 4000000000009995
Insufficient funds: 4000000000009995
```

## Important Methods

### StripeService
```dart
// Create hold
await stripeService.createPreAuthorization(
  amount: "25.00",
  currency: "usd",
);

// Capture payment
await stripeService.capturePreAuthorization(
  paymentIntentId: "pi_xxx",
  finalAmount: "23.50",
);

// Release hold
await stripeService.releasePreAuthorization(
  paymentIntentId: "pi_xxx",
);
```

### HomeController
```dart
// Booking with pre-auth (automatic when Stripe selected)
await controller.bookRide();
```

### PaymentOrderController
```dart
// Capture on completion (automatic)
await controller.completeOrder();

// Release on cancellation
await controller.handleRideCancellation();
```

## Configuration

**Firebase (payment_gateway collection):**
```json
{
  "strip": {
    "enable": true,
    "clientpublishableKey": "pk_test_...",
    "stripeSecret": "sk_test_...",
    "name": "Stripe",
    "isSandbox": true
  }
}
```

## Error Handling

### Common Errors

**"Stripe is not configured properly"**
- Check Firebase payment settings
- Verify both keys are set

**"Insufficient balance"**
- Expected behavior
- User should try different payment

**"Payment authorization failed"**
- Network or API issue
- Check Stripe dashboard

## Debugging

### Enable Logs
Look for these console outputs:
```
🔄 - Processing
✅ - Success
❌ - Error
💰 - Payment related
🚗 - Ride related
```

### Check Order Status
```dart
print(orderModel.paymentIntentId);        // Should have value
print(orderModel.paymentIntentStatus);     // "requires_capture" or "captured"
print(orderModel.preAuthAmount);           // Initial auth amount
```

### Stripe Dashboard
1. Go to dashboard.stripe.com
2. View Payments
3. Search by payment intent ID
4. Check status and events

## Flow Diagrams

### Booking Flow
```
User selects Stripe
    ↓
Calculate fare
    ↓
Create payment intent (manual capture)
    ↓
Present payment sheet
    ↓
User authorizes → Success
    |              ↓
    |         Store intent ID
    |              ↓
    |         Create order
    |              ↓
    |         Find driver
    ↓
Card declined → Show "Insufficient balance"
```

### Completion Flow
```
Ride completes
    ↓
Get payment intent ID from order
    ↓
Calculate final fare
    ↓
Capture amount from hold
    ↓
Update payment status
    ↓
Complete order processing
```

### Cancellation Flow
```
Ride cancelled
    ↓
Get payment intent ID
    ↓
Cancel payment intent
    ↓
Release hold
    ↓
Show confirmation
```

## Integration Checklist

- [x] StripeService created
- [x] OrderModel updated with tracking fields
- [x] HomeController implements pre-auth
- [x] PaymentOrderController captures on completion
- [x] Cancellation releases holds
- [x] "Insufficient balance" toast implemented
- [x] Error handling added
- [x] Logging implemented
- [ ] Test with real Stripe account
- [ ] Update Firebase production config
- [ ] Test all scenarios
- [ ] Deploy to production

## Best Practices

1. **Always Test in Sandbox:**
   - Use test keys first
   - Verify all flows work
   - Check Stripe dashboard

2. **Monitor Logs:**
   - Watch for errors
   - Track success rates
   - Debug issues quickly

3. **Handle Errors Gracefully:**
   - Show user-friendly messages
   - Log technical details
   - Provide alternatives

4. **Security:**
   - Never log sensitive data
   - Keep secret keys secure
   - Validate all amounts

## Common Modifications

### Change Currency
```dart
// In home_controller.dart, line ~543
currency: "cad",  // Change to your currency
```

### Adjust Timeout
```dart
// In stripe_service.dart, add timeout
await http.post(url)
  .timeout(Duration(seconds: 30));
```

### Custom Error Messages
```dart
// In home_controller.dart, around line 580
ShowToastDialog.showToast("Your custom message");
```

## Support

**Issues:**
- Check STRIPE_AUTHORIZATION_FLOW.md for details
- Review logs for error messages
- Verify Stripe dashboard

**Questions:**
- Refer to IMPLEMENTATION_SUMMARY.md
- Check Stripe documentation
- Review code comments

## Next Steps

1. Read STRIPE_AUTHORIZATION_FLOW.md for detailed flow
2. Review IMPLEMENTATION_SUMMARY.md for all changes
3. Test thoroughly with test cards
4. Configure production Stripe keys
5. Deploy and monitor
