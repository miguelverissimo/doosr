# frozen_string_literal: true

class ItemNotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item

  def create
    @notification = current_user.notifications.build(
      item: @item,
      remind_at: parse_remind_at,
      status: "pending",
      channels: [ "push", "in_app" ]
    )

    if @notification.save
      respond_to do |format|
        format.turbo_stream do
          streams = [
            turbo_stream.replace(
              "sheet_content_area",
              ::Views::Items::RemindersSection.new(item: @item, day: @day)
            ),
            turbo_stream.append(
              "body",
              "<script>window.toast && window.toast('Reminder added', { type: 'success' })</script>"
            )
          ]

          # Update the item's reminder indicator if in day view
          if @day
            streams << turbo_stream.replace(
              "item_#{@item.id}",
              ::Views::Items::CompletableItem.new(record: @item.reload, day: @day)
            )
          end

          render turbo_stream: streams
        end
        format.html { redirect_back(fallback_location: root_path, notice: "Reminder created") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          error_message = @notification.errors.full_messages.join(", ")
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast(#{error_message.to_json}, { type: 'error' })</script>"
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Failed to create reminder") }
      end
    end
  end

  private

  def set_item
    @item = current_user.items.find(params[:item_id])
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
  end

  def parse_remind_at
    remind_at_param = params[:remind_at]
    return nil if remind_at_param.blank?

    Time.zone.parse(remind_at_param)
  end
end
