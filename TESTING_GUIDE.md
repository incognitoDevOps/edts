# Stripe Authorization - Testing Guide

## Quick Test Steps

### Test 1: Successful Authorization and Booking

1. **Open App** → Go to home screen
2. **Enter Locations:**
   - Tap source location
   - Enter pickup address
   - Tap destination location
   - Enter dropoff address
3. **Calculate Route:**
   - Wait for route calculation
   - Verify amount shows in booking button
4. **Open Booking Details:**
   - Tap "Book Ride" button
   - Booking details screen opens
5. **Select Stripe Payment:**
   - Tap on payment method section
   - Payment dialog opens
   - Tap "Stripe" option
   - **Payment sheet should appear immediately**
6. **Authorize Payment:**
   - Enter card: `4242 4242 4242 4242`
   - Enter any future expiry date
   - Enter any 3-digit CVC
   - Tap "Pay" or "Authorize"
7. **Verify Authorization:**
   - Payment sheet closes
   - Back on booking details screen
   - See green checkmark ✓
   - See "Payment Authorized" text
8. **Book Ride:**
   - Tap "Book Ride" button
   - **Should succeed without showing payment sheet again**
   - Navigate to ride tracking screen

**Expected Result:** ✅ Ride booked successfully with Stripe pre-authorization

---

### Test 2: Insufficient Balance

1. **Follow steps 1-5 from Test 1**
2. **Select Stripe Payment**
3. **Authorize with Declined Card:**
   - Enter card: `4000 0000 0000 9995`
   - Enter any future expiry date
   - Enter any 3-digit CVC
   - Tap "Pay" or "Authorize"
4. **Verify Error Handling:**
   - See toast message: "Insufficient balance"
   - Payment method NOT selected
   - Still on booking details screen
5. **Try Different Method:**
   - Can select Wallet or Cash
   - Or try different card

**Expected Result:** ✅ Clear error message, payment not selected

---

### Test 3: Cancel Payment Authorization

1. **Follow steps 1-5 from Test 1**
2. **Select Stripe Payment**
3. **Cancel Payment Sheet:**
   - Payment sheet appears
   - Tap back button or close (X)
   - Don't enter card details
4. **Verify Cancellation:**
   - See toast: "Payment authorization cancelled"
   - Payment method NOT selected
   - Back on booking details screen
5. **Try Again:**
   - Can tap payment method again
   - Select Stripe again
   - Complete authorization this time

**Expected Result:** ✅ Can cancel and retry without issues

---

### Test 4: Complete Ride Flow

1. **Book ride with Stripe (Test 1)**
2. **Wait for driver acceptance**
3. **Complete the ride**
4. **Go to Payment screen**
5. **Verify:**
   - Payment captured automatically
   - Amount correct
   - Ride marked as complete

**Expected Result:** ✅ Payment captured from pre-authorization

---

### Test 5: Cancel Ride with Stripe

1. **Book ride with Stripe (Test 1)**
2. **Before driver accepts:**
   - Cancel the ride
3. **Verify:**
   - Ride cancelled
   - Pre-authorization released
   - See confirmation message

**Expected Result:** ✅ Authorization released on cancellation

---

## Stripe Test Cards

### Success Cards
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/25)
CVC: Any 3 digits (e.g., 123)
ZIP: Any (e.g., 12345)
```

### Declined - Insufficient Funds
```
Card Number: 4000 0000 0000 9995
Expiry: Any future date
CVC: Any 3 digits
ZIP: Any
```

### Other Test Cards
```
Generic Decline: 4000 0000 0000 0002
Expired Card: 4000 0000 0000 0069
Processing Error: 4000 0000 0000 0119
```

Full list: https://stripe.com/docs/testing

---

## Console Log Checklist

### During Payment Selection (Stripe)

Look for these logs:
```
🔄 - Processing payment authorization
✅ - Pre-authorization created successfully
💰 - Amount calculations
```

### During Booking

Look for these logs:
```
✅ Using pre-authorized payment: pi_xxxxx
🔍 Verifying commission data...
```

### During Ride Completion

Look for these logs:
```
💰 [PAYMENT DEBUG] Starting completeOrder process...
🔄 Step 1-7: Various completion steps
✅ Pre-authorization captured successfully
🎉 PAYMENT COMPLETE SUCCESSFULLY!
```

---

## Verification Checklist

- [ ] Payment sheet appears when selecting Stripe
- [ ] "Payment Authorized ✓" shows after authorization
- [ ] "Insufficient balance" shows for declined cards
- [ ] Can cancel authorization and retry
- [ ] Booking works without second payment prompt
- [ ] Payment captured on ride completion
- [ ] Authorization released on cancellation
- [ ] Other payment methods (Wallet, Cash) still work
- [ ] No exceptions or crashes
- [ ] Console logs show expected flow

---

## Stripe Dashboard Verification

1. **Go to:** https://dashboard.stripe.com
2. **Navigate to:** Payments → All payments
3. **Verify:**
   - New payment intents created when selecting Stripe
   - Status shows "Requires capture" after authorization
   - Status changes to "Succeeded" after ride completion
   - Status shows "Canceled" if ride cancelled

---

## Common Issues During Testing

### Issue: Payment sheet doesn't appear

**Possible Causes:**
- Route not calculated yet
- Stripe not configured
- Invalid Stripe keys

**Fix:**
- Ensure destination is selected
- Check Firebase configuration
- Verify keys are correct

### Issue: "Stripe is not configured properly"

**Fix:**
- Go to Firebase Console
- Check `payment_gateway` collection
- Verify `strip` document has:
  - `enable: true`
  - `clientpublishableKey: pk_...`
  - `stripeSecret: sk_...`

### Issue: Authorization works but booking fails

**Check Console For:**
```
❌ Please select Stripe payment method again
```

**Fix:**
- This shouldn't happen with new code
- If it does, clear app data and retry
- Check `stripePaymentIntentId` is set

### Issue: Amount incorrect

**Verify:**
- Tax calculation included?
- Coupon applied correctly?
- Commission calculated?

---

## Performance Testing

### Test Scenarios

1. **Fast Selection:**
   - Select Stripe immediately after route calculation
   - Should work smoothly

2. **Slow Network:**
   - Test with throttled network
   - Verify loading states show
   - Timeout handling works

3. **Multiple Attempts:**
   - Cancel and retry multiple times
   - Should not accumulate errors
   - Memory should not leak

4. **Different Amounts:**
   - Short ride (small amount)
   - Long ride (large amount)
   - Both should work

---

## Success Criteria

✅ **All tests pass without errors**
✅ **User sees clear feedback at each step**
✅ **"Insufficient balance" shows for declined cards**
✅ **Authorization indicator appears after success**
✅ **Booking completes without payment interruption**
✅ **Payment captured on completion**
✅ **Authorization released on cancellation**
✅ **No exceptions or crashes**
✅ **Console logs show expected flow**
✅ **Stripe dashboard shows correct status**

---

## Regression Testing

Ensure these still work:

- [ ] Wallet payment
- [ ] Cash payment
- [ ] Other payment gateways
- [ ] Coupon application
- [ ] Tax calculation
- [ ] Commission calculation
- [ ] Ride tracking
- [ ] Driver matching
- [ ] Notifications

---

## Load Testing

If testing in production:

1. **Start Small:**
   - Test with 1-2 users first
   - Verify everything works

2. **Monitor:**
   - Stripe dashboard for failures
   - App logs for errors
   - User feedback

3. **Scale Up:**
   - Gradually increase users
   - Watch for any issues

---

## Rollback Plan

If critical issues found:

1. **Quick Fix:**
   - Disable Stripe in Firebase
   - Set `enable: false` in payment_gateway
   - Users can use other methods

2. **Code Rollback:**
   - Revert to previous version
   - Investigate issues
   - Fix and redeploy

---

## Support During Testing

**Report Issues With:**
1. Exact steps to reproduce
2. Screenshot of error
3. Console logs
4. Stripe dashboard screenshot
5. Device/OS information

**Check These First:**
- Firebase configuration
- Stripe keys validity
- App version up to date
- Network connectivity

---

## Testing Timeline

**Day 1: Basic Testing**
- Test 1: Successful flow ✅
- Test 2: Insufficient balance ✅
- Test 3: Cancellation ✅

**Day 2: Integration Testing**
- Test 4: Complete ride flow ✅
- Test 5: Cancellation with refund ✅
- Regression tests ✅

**Day 3: Edge Cases**
- Network issues
- Multiple attempts
- Different amounts
- Performance testing

**Day 4: Production Verification**
- Monitor real transactions
- User feedback
- Dashboard verification

---

## Ready for Production?

Before going live:

- [ ] All tests passed
- [ ] No critical issues found
- [ ] Stripe keys switched to production
- [ ] Firebase production config updated
- [ ] Support team briefed
- [ ] Rollback plan ready
- [ ] Monitoring setup
- [ ] User documentation updated

---

## Contact for Issues

- Technical Issues: Check console logs first
- Configuration Issues: Verify Firebase settings
- Stripe Issues: Check Stripe dashboard
- User Experience Issues: Note exact steps to reproduce
