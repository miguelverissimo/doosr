# frozen_string_literal: true

namespace :notifications do
  desc "Generate VAPID keys for push notifications"
  task generate_vapid_keys: :environment do
    require "openssl"
    require "base64"

    # Generate VAPID keys using OpenSSL directly (compatible with OpenSSL 3.0)
    curve = ::OpenSSL::PKey::EC.generate("prime256v1")
    private_key = ::Base64.urlsafe_encode64(curve.private_key.to_bn.to_s(2), padding: false)
    public_key = ::Base64.urlsafe_encode64(curve.public_key.to_bn.to_s(2), padding: false)

    puts "\n" + "=" * 80
    puts "VAPID Keys Generated Successfully!"
    puts "=" * 80
    puts "\nAdd these to your production environment variables:\n\n"
    puts "VAPID_PUBLIC_KEY=#{public_key}"
    puts "VAPID_PRIVATE_KEY=#{private_key}"
    puts "VAPID_SUBJECT=mailto:your-email@example.com"
    puts "\n" + "=" * 80
    puts "\nIMPORTANT: Keep the private key secret!"
    puts "=" * 80 + "\n\n"
  end

  desc "Test push notification setup"
  task test_config: :environment do
    puts "\n" + "=" * 80
    puts "Push Notification Configuration Test"
    puts "=" * 80 + "\n"

    # Check environment variables
    required_vars = %w[VAPID_PUBLIC_KEY VAPID_PRIVATE_KEY]
    optional_vars = %w[VAPID_SUBJECT]

    puts "Required Environment Variables:"
    required_vars.each do |var|
      value = ENV[var]
      if value.present?
        puts "  ✓ #{var}: #{value[0..20]}... (#{value.length} chars)"
      else
        puts "  ✗ #{var}: NOT SET"
      end
    end

    puts "\nOptional Environment Variables:"
    optional_vars.each do |var|
      value = ENV[var]
      if value.present?
        puts "  ✓ #{var}: #{value}"
      else
        puts "  - #{var}: Not set (will use default: mailto:admin@doosr.bfsh.app)"
      end
    end

    # Check database tables
    puts "\nDatabase Tables:"
    begin
      if ActiveRecord::Base.connection.table_exists?(:push_subscriptions)
        count = ::PushSubscription.count
        puts "  ✓ push_subscriptions table exists (#{count} subscriptions)"
      else
        puts "  ✗ push_subscriptions table missing - run migrations!"
      end

      if ActiveRecord::Base.connection.table_exists?(:notification_logs)
        count = ::NotificationLog.count
        puts "  ✓ notification_logs table exists (#{count} logs)"
      else
        puts "  ✗ notification_logs table missing - run migrations!"
      end
    rescue StandardError => e
      puts "  ✗ Database error: #{e.message}"
    end

    # Test VAPID key validity
    puts "\nVAPID Key Validation:"
    if ENV["VAPID_PUBLIC_KEY"].present? && ENV["VAPID_PRIVATE_KEY"].present?
      begin
        # Try to use the keys
        test_endpoint = "https://fcm.googleapis.com/fcm/send/test"
        ::Webpush.payload_send(
          message: '{"test": true}',
          endpoint: test_endpoint,
          p256dh: "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=",
          auth: "tBHItJI5svbpez7KI4CCXg==",
          vapid: {
            subject: ENV.fetch("VAPID_SUBJECT", "mailto:test@example.com"),
            public_key: ENV["VAPID_PUBLIC_KEY"],
            private_key: ENV["VAPID_PRIVATE_KEY"]
          }
        )
        puts "  ✓ VAPID keys appear valid (test endpoint call succeeded)"
      rescue ::Webpush::InvalidSubscription
        # This is expected - we're using a fake endpoint
        puts "  ✓ VAPID keys are properly formatted"
      rescue StandardError => e
        puts "  ✗ VAPID key error: #{e.message}"
      end
    else
      puts "  - Skipped (keys not set)"
    end

    puts "\n" + "=" * 80 + "\n"
  end
end
