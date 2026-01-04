# Fix Push Notifications in Production - Quick Guide

## What's Wrong

The "AbortError: Registration failed - push service error" happens because:
1. ❌ VAPID keys are not set in Coolify environment variables
2. ❌ Database migrations haven't run (missing `push_subscriptions` and `notification_logs` tables)

## Quick Fix (5 minutes)

### Step 1: Generate VAPID Keys (locally)

```bash
bin/rails notifications:generate_vapid_keys
```

Copy the three values that are printed.

### Step 2: Add to Coolify

1. Open Coolify dashboard
2. Go to your Doosr application
3. Click **Settings → Environment Variables**
4. Add these three variables (paste the values from Step 1):
   - `VAPID_PUBLIC_KEY`
   - `VAPID_PRIVATE_KEY`
   - `VAPID_SUBJECT`
5. Click **Save**

### Step 3: Redeploy

1. Click **Redeploy** in Coolify
2. Wait for deployment to complete
3. Migrations will run automatically

### Step 4: Verify

1. Go to `/admin/notifications` in production
2. You should see NO red warning banner
3. Click "Enable Notifications"
4. Browser should ask for permission ✅
5. Send a test notification ✅

## What I Changed in the Code

To prevent crashes and show better errors, I updated:

1. **app/views/admin/notification_permission_status.rb**:
   - Shows red warning banner when VAPID keys missing
   - Disables "Enable Notifications" button until configured

2. **app/javascript/controllers/notification_permission_controller.js**:
   - Checks for missing VAPID keys before attempting subscription
   - Better error messages for different failure scenarios

3. **lib/tasks/notifications.rake**:
   - New task to generate VAPID keys: `bin/rails notifications:generate_vapid_keys`
   - New task to test config: `bin/rails notifications:test_config`

## Before vs After

**Before:**
- ❌ Generic "AbortError" in console
- ❌ No indication why it failed
- ❌ Attempts to subscribe even without keys

**After:**
- ✅ Red warning banner if keys not configured
- ✅ Clear error messages
- ✅ Button disabled until configured
- ✅ Helpful instructions in UI

---

For detailed documentation, see `NOTIFICATIONS_DEPLOYMENT.md`
