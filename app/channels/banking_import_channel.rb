# frozen_string_literal: true

class BankingImportChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user

    stream_from "banking_import:#{current_user.id}"

    Rails.logger.debug "=== BankingImportChannel subscribed for user #{current_user.id} ==="
  end

  def unsubscribed
    Rails.logger.debug "=== BankingImportChannel unsubscribed for user #{current_user&.id} ==="
  end
end
