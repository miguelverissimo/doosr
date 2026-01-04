# frozen_string_literal: true

module PushNotifications
  # Service for managing push notification subscriptions
  #
  # This service:
  # - Creates new subscriptions from browser subscription objects
  # - Updates existing subscriptions
  # - Removes subscriptions
  # - Validates subscription data
  #
  # Returns: { success: Boolean, subscription: PushSubscription, error: String }
  class SubscriptionManager
    attr_reader :user, :subscription_data, :user_agent

    def initialize(user:, subscription_data:, user_agent: nil)
      @user = user
      @subscription_data = subscription_data
      @user_agent = user_agent
    end

    def subscribe
      ActiveRecord::Base.transaction do
        # Parse subscription data
        endpoint = subscription_data["endpoint"]
        keys = subscription_data["keys"]

        # Find or create subscription
        subscription = user.push_subscriptions.find_or_initialize_by(endpoint: endpoint)

        subscription.assign_attributes(
          p256dh_key: keys["p256dh"],
          auth_key: keys["auth"],
          user_agent: user_agent,
          last_used_at: Time.current
        )

        if subscription.save
          { success: true, subscription: subscription }
        else
          { success: false, error: subscription.errors.full_messages.join(", ") }
        end
      end
    rescue StandardError => e
      Rails.logger.error "Subscription failed: #{e.message}"
      { success: false, error: e.message }
    end

    def unsubscribe(endpoint)
      subscription = user.push_subscriptions.find_by(endpoint: endpoint)
      return { success: false, error: "Subscription not found" } unless subscription

      if subscription.destroy
        { success: true }
      else
        { success: false, error: "Failed to remove subscription" }
      end
    rescue StandardError => e
      Rails.logger.error "Unsubscribe failed: #{e.message}"
      { success: false, error: e.message }
    end
  end
end
