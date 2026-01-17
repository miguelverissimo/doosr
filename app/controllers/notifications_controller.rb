# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :show, :destroy ]

  def index
    @notifications = current_user.unread_notifications.limit(10)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "notification_bell",
          ::Components::NotificationsDropdown.new(notifications: @notifications)
        )
      end
    end
  end

  def mark_all_read
    ::Notifications::MarkAllReadService.new(current_user).call

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
            "notification_badge",
            ::Components::NotificationBadge.new(count: 0)
          ),
          turbo_stream.replace(
            "notifications_dropdown",
            ::Components::NotificationsDropdown.new(notifications: [])
          )
        ]
      end
    end
  end

  def show
    @notification.mark_read!

    day = find_root_day(@notification.item)

    if day
      redirect_to day_path(date: day.date, highlight: @notification.item_id), allow_other_host: false
    else
      redirect_to authenticated_root_path, alert: "Could not find item location"
    end
  end

  def destroy
    @item = @notification.item
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?

    @notification.destroy!

    respond_to do |format|
      format.turbo_stream do
        streams = [
          turbo_stream.replace(
            "sheet_content_area",
            ::Views::Items::RemindersSection.new(item: @item.reload, day: @day)
          ),
          turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Reminder deleted', { type: 'success' })</script>"
          )
        ]

        if @day
          streams << turbo_stream.replace(
            "item_#{@item.id}",
            ::Views::Items::CompletableItem.new(record: @item.reload, day: @day)
          )
        end

        render turbo_stream: streams
      end
      format.html { redirect_back(fallback_location: root_path, notice: "Reminder deleted") }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def find_root_day(item)
    return nil unless item

    containing_descendant = Descendant.containing_item(item.id)
    return nil unless containing_descendant

    descendable = containing_descendant.descendable

    while descendable.is_a?(Item)
      containing_descendant = Descendant.containing_item(descendable.id)
      break unless containing_descendant

      descendable = containing_descendant.descendable
    end

    descendable.is_a?(Day) ? descendable : nil
  end
end
