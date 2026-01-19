# frozen_string_literal: true

class BankingRecurringChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user

    stream_from "banking_recurring:#{current_user.id}"

    Rails.logger.debug "=== BankingRecurringChannel subscribed for user #{current_user.id} ==="
  end

  def unsubscribed
    Rails.logger.debug "=== BankingRecurringChannel unsubscribed for user #{current_user&.id} ==="
  end
end
