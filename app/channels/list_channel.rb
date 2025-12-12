class ListChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.debug "=== ListChannel subscription attempt ==="
    Rails.logger.debug "Params: #{params.inspect}"
    Rails.logger.debug "List ID: #{params[:list_id]}"

    stream_from "list_channel:#{params[:list_id]}"

    Rails.logger.debug "=== Subscribed to list_channel:#{params[:list_id]} ==="
  end

  def unsubscribed
    Rails.logger.debug "=== ListChannel unsubscribed for list #{params[:list_id]} ==="
  end
end
