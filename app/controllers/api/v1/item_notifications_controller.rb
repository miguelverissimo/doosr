# frozen_string_literal: true

module Api
  module V1
    class ItemNotificationsController < Api::BaseController
      before_action :authorize_item_access!
      before_action :set_item

      resource_description do
        short "Item Notifications"
        description "Manage reminders/notifications for items"
        meta group: "Tasks & Planning"
        formats [ "json" ]
      end

      api :GET, "/items/:item_id/notifications", "List notifications for an item"
      description "Returns all pending notifications for the given item."
      param :item_id, :number, desc: "Item ID", required: true
      def index
        notifications = @item.notifications.pending.order(:remind_at)

        render json: {
          data: notifications.map { |n| serialize_notification(n) },
          meta: { total: notifications.size }
        }, status: :ok
      end

      api :POST, "/items/:item_id/notifications", "Create a notification for an item"
      description "Schedules a reminder notification for the given item."
      param :item_id, :number, desc: "Item ID", required: true
      param :remind_at, String, desc: "When to send the reminder (ISO 8601 datetime)", required: true
      def create
        notification = current_user.notifications.build(
          item: @item,
          remind_at: parse_remind_at,
          status: "pending",
          channels: [ "push", "in_app" ]
        )

        if notification.save
          render json: {
            data: serialize_notification(notification),
            meta: {}
          }, status: :created
        else
          render_error(
            notification.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: notification.errors.full_messages
          )
        end
      end

      api :DELETE, "/items/:item_id/notifications/:id", "Delete a notification"
      description "Deletes a pending notification for the given item."
      param :item_id, :number, desc: "Item ID", required: true
      param :id, :number, desc: "Notification ID", required: true
      def destroy
        notification = current_user.notifications.find(params[:id])

        unless notification.item_id == @item.id
          render_error("Notification does not belong to this item", status: :unprocessable_entity)
          return
        end

        notification.destroy!

        render json: { data: nil, meta: {} }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      private

      def authorize_item_access!
        authorize_feature!(:day)
      end

      def set_item
        @item = current_user.items.find(params[:item_id])
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      def parse_remind_at
        return nil if params[:remind_at].blank?

        Time.zone.parse(params[:remind_at])
      end

      def serialize_notification(notification)
        {
          id: notification.id,
          item_id: notification.item_id,
          remind_at: notification.remind_at.iso8601,
          status: notification.status,
          channels: notification.channels,
          created_at: notification.created_at.iso8601,
          updated_at: notification.updated_at.iso8601
        }
      end
    end
  end
end
