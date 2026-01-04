# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    result = ::PushNotifications::SubscriptionManager.new(
      user: current_user,
      subscription_data: subscription_params.to_h,
      user_agent: request.user_agent
    ).subscribe

    respond_to do |format|
      if result[:success]
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "notification_permission_section",
            ::Views::Admin::NotificationPermissionStatus.new(
              user: current_user,
              subscribed: true
            )
          )
        end
        format.json { render json: { success: true }, status: :created }
      else
        format.json { render json: { error: result[:error] }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    result = ::PushNotifications::SubscriptionManager.new(
      user: current_user,
      subscription_data: {}
    ).unsubscribe(params[:endpoint])

    respond_to do |format|
      if result[:success]
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "notification_permission_section",
            ::Views::Admin::NotificationPermissionStatus.new(
              user: current_user,
              subscribed: false
            )
          )
        end
        format.json { render json: { success: true }, status: :ok }
      else
        format.json { render json: { error: result[:error] }, status: :unprocessable_entity }
      end
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, keys: [ :p256dh, :auth ])
  end
end
