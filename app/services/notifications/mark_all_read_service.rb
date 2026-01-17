# frozen_string_literal: true

module Notifications
  class MarkAllReadService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      now = Time.current
      count = user.notifications.unread.update_all(status: "read", read_at: now, updated_at: now)

      { success: true, count: count }
    end
  end
end
