# Payment System Testing Checklist

## Pre-Deployment Testing (Required)

### Test 1: Normal Stripe Payment ✅
**Steps**:
1. Open app → Book ride
2. Select Stripe as payment method
3. Use test card: 4242 4242 4242 4242
4. Complete authorization
5. Wait for driver assignment
6. Driver completes ride
7. **Expected**: Payment automatically captured
8. **Verify**:
   - Transaction appears in wallet history
   - Order status = "succeeded"
   - User receives confirmation

**Pass Criteria**: Payment captured within 10 seconds

---

### Test 2: Cancellation Before Completion ✅
**Steps**:
1. Book ride with Stripe
2. Use test card: 4242 4242 4242 4242
3. Complete authorization
4. **Immediately cancel the ride**
5. **Expected**: Pre-authorization released
6. **Verify**:
   - Notification says "funds released"
   - Transaction shows cancellation
   - Order status = "canceled"

**Pass Criteria**: Release confirmation within 30 seconds

---

### Test 3: Network Interruption Recovery ✅
**Steps**:
1. Book ride with Stripe
2. Driver completes ride
3. **Turn on airplane mode before clicking complete**
4. Try to complete payment (will fail)
5. **Turn off airplane mode**
6. **Expected**: System retries automatically
7. **Verify**: Payment captured after retry

**Pass Criteria**: Successful capture within 60 seconds

---

### Test 4: Declined Card Handling ✅
**Steps**:
1. Book ride with declined test card: 4000 0000 0000 0002
2. **Expected**: Authorization fails immediately
3. **Verify**:
   - Clear error message shown
   - Booking NOT created
   - User can retry with different card

**Pass Criteria**: Clear error message, no broken booking

---

### Test 5: Validation Check ✅
**Steps**:
1. Attempt to book ride
2. If payment authorization fails, booking should be rejected
3. **Verify**:
   - User sees "Payment authorization error"
   - No order created in Firestore
   - User can retry

**Pass Criteria**: System prevents incomplete bookings

---

## Verification Points

After each test, check:

### Firestore
```
Collection: orders
- paymentIntentId: Should exist for Stripe payments
- paymentIntentStatus: Should be "requires_capture" or "succeeded"
- preAuthAmount: Should match booking amount
```

### Transaction History
```
Collection: walletTransaction
- Authorization transaction (when booking)
- Capture transaction (when completing)
- Cancellation transaction (if canceled)
```

### Stripe Dashboard
```
Payments → Should show:
- Authorized payments (during ride)
- Captured payments (after completion)
- Canceled payments (if canceled)
```

---

## Common Issues & Solutions

### Issue: "Payment authorization error"
**Cause**: Stripe authorization failed
**Solution**:
- Check internet connection
- Try different card
- Verify Stripe keys in Firebase config

### Issue: "Payment capture failed"
**Cause**: Network timeout or expired payment intent
**Solution**:
- System automatically retries 3 times
- If all fail, check Firestore `capture_failures` collection
- Contact support if payment intent >7 days old

### Issue: Payment stuck in "requires_capture"
**Cause**: All retry attempts failed
**Solution**:
- Check network connectivity
- Check Stripe Dashboard for payment intent status
- If needed, manually capture in Stripe Dashboard

---

## Test Environment Setup

### Stripe Test Mode
```
Use test API keys from Stripe Dashboard
Test cards never charge real money
```

### Test Cards
```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
Insufficient funds: 4000 0000 0000 9995
```

### Firebase
```
Use staging/test project
Don't test on production database
```

---

## Production Deployment Checklist

Before going live:
- [ ] All 5 tests pass
- [ ] Stripe live keys configured
- [ ] Firebase production database ready
- [ ] Backup current code
- [ ] Monitor logs for first 24 hours
- [ ] Check Stripe Dashboard daily for first week

---

## Monitoring (Post-Deployment)

### Daily Checks (First Week)
- [ ] Check Stripe Dashboard for uncaptured payments
- [ ] Review Firestore `capture_failures` collection
- [ ] Verify all transactions have history entries
- [ ] Check for user complaints

### Weekly Checks (Ongoing)
- [ ] Review payment success rate (should be >99%)
- [ ] Check average capture time (should be <10s)
- [ ] Monitor cancellation refunds
- [ ] Review error logs

---

## Success Metrics

### Target Metrics:
- **Capture Success Rate**: >99%
- **Average Capture Time**: <10 seconds
- **Cancellation Release Time**: <2 minutes
- **Failed Captures**: <1% (with retry)
- **User Complaints**: <5 per month

---

## Emergency Contacts

### If Critical Payment Issue:
1. **Check Logs**: Look for error messages
2. **Check Firestore**: `capture_failures` collection
3. **Check Stripe Dashboard**: Payment intent status
4. **Manual Fix**: Capture/refund in Stripe Dashboard if needed

### Stripe Support:
- Dashboard: https://dashboard.stripe.com
- Support: https://support.stripe.com
- Docs: https://stripe.com/docs

---

**Remember**: Test thoroughly before production. Financial transactions require extra care!

**Last Updated**: Current Session
**Status**: Ready for Testing
