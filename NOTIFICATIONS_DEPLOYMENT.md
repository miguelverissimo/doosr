# Push Notifications - Production Deployment Guide (Coolify)

## Issues Found in Production

1. **Missing database tables**: `push_subscriptions` and `notification_logs` tables don't exist
2. **Invalid VAPID keys**: Environment variables not properly configured

## Step-by-Step Fix for Coolify

### 1. Generate VAPID Keys (Run Locally)

Generate new VAPID keys using the rake task:

```bash
bin/rails notifications:generate_vapid_keys
```

This will output something like:

```
VAPID_PUBLIC_KEY=BHYCuY2sJnN-G_QAYaXta9wji0VBY3NZON7giGYr_Weld849ngBaQN5YYt3JLFeSLSfMBiW-R-zp-XSiKJ5TDwA
VAPID_PRIVATE_KEY=llEnZgBe3QPt0ObUpwReUfaXiIQNihGyIGWrh1gLPgA
VAPID_SUBJECT=mailto:your-email@example.com
```

**IMPORTANT**:
- Generate these keys ONCE and save them securely
- The same keys must be used across all deployments
- If you change the keys, all existing subscriptions will break

### 2. Set Environment Variables in Coolify

Add these three environment variables via the Coolify UI:

1. **Open Coolify Dashboard**
2. **Navigate to your Doosr application**
3. **Go to Settings → Environment Variables**
4. **Add the following variables**:
   - `VAPID_PUBLIC_KEY` = `<your-generated-public-key>`
   - `VAPID_PRIVATE_KEY` = `<your-generated-private-key>`
   - `VAPID_SUBJECT` = `mailto:admin@doosr.bfsh.app` (or your preferred email)

5. **Click "Save"**

### 3. Redeploy the Application

After setting environment variables, redeploy the application:

1. In Coolify UI, go to your application
2. Click "Redeploy" or trigger a new deployment
3. **Migrations run automatically** via `bin/docker-entrypoint` script

The migrations that will run automatically:
- `20260103063542_add_notification_time_to_items.rb`
- `20260103063611_create_push_subscriptions.rb`
- `20260103063642_create_notification_logs.rb`

### 4. Verify Migrations Ran (Optional)

If you want to verify migrations ran successfully:

1. **Open Coolify Terminal**:
   - Go to your application in Coolify UI
   - Click "Terminal" or "Execute Command"

2. **Check migration status**:
   ```bash
   bin/rails db:migrate:status
   ```

3. **Manually run migrations if needed** (only if automatic migration failed):
   ```bash
   bin/rails db:migrate
   ```

### 5. Verify the Setup

After deploying with environment variables, test the configuration:

#### In Production Console (via Coolify Terminal)
1. **Open Coolify Terminal**:
   - Go to your application in Coolify UI
   - Click "Terminal" or "Execute Command"

2. **Run the test configuration task**:
   ```bash
   bin/rails notifications:test_config
   ```

This will check:
- ✓ Environment variables are set
- ✓ Database tables exist
- ✓ VAPID keys are valid

#### In Browser
1. Go to `/admin/notifications`
2. You should see the notification settings page (no errors)
3. Click "Enable Notifications"
4. Browser should ask for permission
5. After granting permission, you should see "Notifications enabled"
6. Try sending a test notification

## Troubleshooting

### "Invalid VAPID key" error persists

1. **Check the keys are properly set in Coolify**:
   - Go to Settings → Environment Variables in Coolify UI
   - Verify `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT` are set
   - Check for typos or extra spaces

2. **Verify in production console** (via Coolify Terminal):
   ```bash
   # In production terminal
   bin/rails runner "puts ENV['VAPID_PUBLIC_KEY']"
   bin/rails runner "puts ENV['VAPID_PRIVATE_KEY']"
   ```

3. **Verify key format**:
   - Public key should be ~87 characters, start with "B"
   - Private key should be ~43 characters
   - No spaces or line breaks

4. **Redeploy the application** after setting environment variables:
   - In Coolify UI, click "Redeploy"
   - Wait for deployment to complete

### "relation push_subscriptions does not exist" error

This means migrations weren't run automatically.

**Fix**:
1. Open Coolify Terminal for your application
2. Run migrations manually:
   ```bash
   bin/rails db:migrate
   ```
3. Check the deployment logs to see why automatic migrations failed

### Notifications work but aren't received

1. Check notification logs in `/admin/notifications`
2. Verify the service worker is registered (check browser console)
3. Make sure the app is running on HTTPS (required for push notifications)
4. Check browser notification permissions

### Chrome-specific "AbortError" but works in Firefox

Chrome has stricter requirements than Firefox. If you get "AbortError: Registration failed - push service error" in Chrome but it works in Firefox:

**Cause**: Chrome requires `gcm_sender_id` in manifest.json even when using VAPID

**Fix**: The manifest.json already includes `"gcm_sender_id": "103953800507"` - this is a standard value for VAPID-based push.

**After deploying:**
1. Clear Chrome cache (Ctrl+Shift+Delete → Cached images and files)
2. Unregister service worker in Chrome DevTools (Application → Service Workers → Unregister)
3. Hard reload (Ctrl+Shift+R)
4. Try enabling notifications again

## Security Notes

- **NEVER commit VAPID keys to git**
- Keep the private key secret (treat it like a password)
- Use different keys for development and production
- If keys are compromised, regenerate them and update all subscriptions

## Files Changed

- `lib/tasks/notifications.rake` - New rake tasks for key generation and testing
- `NOTIFICATIONS_DEPLOYMENT.md` - This deployment guide

## Related Migrations

```ruby
# 20260103063611_create_push_subscriptions.rb
create_table :push_subscriptions do |t|
  t.references :user, null: false, foreign_key: true
  t.string :endpoint, null: false
  t.text :p256dh_key, null: false
  t.text :auth_key, null: false
  t.string :user_agent
  t.datetime :last_used_at
  t.timestamps
end

# 20260103063642_create_notification_logs.rb (assumed structure)
create_table :notification_logs do |t|
  t.references :user, null: false, foreign_key: true
  t.references :push_subscription, foreign_key: true
  t.references :item, foreign_key: true
  t.string :notification_type
  t.string :status
  t.json :payload
  t.text :error_message
  t.datetime :sent_at
  t.timestamps
end
```
